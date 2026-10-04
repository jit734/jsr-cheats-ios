import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject, targetBundleID: String? = nil) throws -> PatchTransactionReceipt {
        let activeProject = targetBundleID != nil ? remapProject(project, to: targetBundleID!) : project
        let bundleIDs = orderedBundleIdentifiers(in: activeProject)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.apply(
                project: activeProject,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    private static func remapProject(_ project: PatchProject, to targetBundleID: String) -> PatchProject {
        let isSourceSame = project.allBundleIdentifiers.allSatisfy { $0.caseInsensitiveCompare(targetBundleID) == .orderedSame }
        if isSourceSame && !project.rules.isEmpty && project.rules.allSatisfy({ $0.bundleID.caseInsensitiveCompare(targetBundleID) == .orderedSame }) {
            return project
        }

        let newRules = project.rules.map { rule -> PatchRule in
            var r = rule
            let oldBundle = r.bundleID
            if oldBundle.caseInsensitiveCompare(targetBundleID) != .orderedSame {
                r.bundleID = targetBundleID
                if r.relativePath.contains("\(oldBundle).plist") {
                    r.relativePath = r.relativePath.replacingOccurrences(of: "\(oldBundle).plist", with: "\(targetBundleID).plist")
                }
            }
            return r
        }

        let newDirectories = project.directories.map { dir -> PatchDirectory in
            var d = dir
            if d.bundleID.caseInsensitiveCompare(targetBundleID) != .orderedSame {
                d.bundleID = targetBundleID
            }
            return d
        }

        return PatchProject(
            id: project.id,
            name: project.name,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
            bundleIdentifiers: [targetBundleID],
            directories: newDirectories,
            rules: newRules
        )
    }

    static func restore(receipt: PatchTransactionReceipt) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    static func allAppliedReceipts(projectID: UUID) -> [PatchTransactionReceipt] {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return [] }
        return PatchTransaction.allAppliedReceipts(projectID: projectID, backupRoot: backupRoot)
    }

    static func restoreAll(projectID: UUID) throws {
        let receipts = allAppliedReceipts(projectID: projectID)
        var failures = 0
        for receipt in receipts {
            do {
                try restore(receipt: receipt)
            } catch {
                failures += 1
            }
        }
        guard failures == 0 else {
            throw PatchPackageError.restoreFailed
        }
        // Only delete the backups after every receipt restored with verification.
        // Deleting them on partial failure would permanently strand patched files.
        if !receipts.isEmpty {
            guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else {
                throw PatchPackageError.restoreFailed
            }
            let projectDir = backupRoot.appendingPathComponent(projectID.uuidString, isDirectory: true)
            try FileManager.default.removeItem(at: projectDir)
        }
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            guard let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
                  ContainerStore.isApplicationContainerPath(path) else {
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
            roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
        }
        return try operation(roots)
    }
}
