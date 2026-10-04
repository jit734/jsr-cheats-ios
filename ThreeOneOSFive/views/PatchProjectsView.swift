import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum PatchPackagePickerPolicy {
    static let packageType = UTType(filenameExtension: "3105") ?? UTType(filenameExtension: "terminalx999") ?? UTType(filenameExtension: "Cryptoric") ?? .data
    static let allowedContentTypes: [UTType] = [packageType, .data]
    static let copiesSelectedDocument = true
}

struct PatchProjectsView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var draftCoordinator: PatchDraftCoordinator
    @StateObject private var store = PatchProjectStore()
    @State private var showCreate = false
    @State private var showImporter = false
    @State private var searchText = ""

    private var filteredItems: [PatchLibraryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.items }
        return store.items.filter { item in
            if item.packageURL.lastPathComponent.localizedCaseInsensitiveContains(query) {
                return true
            }
            guard let project = item.project else { return false }
            return item.displayName.localizedCaseInsensitiveContains(query)
                || project.allBundleIdentifiers.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }
                || project.directories.contains {
                    $0.relativePath.localizedCaseInsensitiveContains(query)
                }
                || project.rules.contains {
                    $0.relativePath.localizedCaseInsensitiveContains(query)
                        || $0.replacementFilename.localizedCaseInsensitiveContains(query)
                }
        }
    }

    init() {
#if targetEnvironment(simulator)
        _showCreate = State(
            initialValue: ProcessInfo.processInfo.arguments.contains("--simulate-patch-editor")
        )
#endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedHyperBackdrop()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    AppSearchField(
                        text: $searchText,
                        prompt: language.text("patch.search"),
                        clearLabel: language.text("common.clear")
                    )
                    .padding(.top, 8)

                    if store.items.isEmpty && !store.isBusy {
                        emptyState
                    } else if filteredItems.isEmpty && !store.isBusy {
                        searchEmptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredItems) { item in
                                    itemRow(item)
                                }
                            }
                            .padding(.horizontal, AppTheme.pageInset)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle(language.text("patch.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showCreate = true
                        } label: {
                            Label(language.text("patch.new"), systemImage: "doc.badge.plus")
                        }
                        Button {
                            showImporter = true
                        } label: {
                            Label(language.text("patch.import"), systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        if store.isBusy {
                            ProgressView()
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(width: 34, height: 34)
                                .claymorphicCircle(depth: 4)
                        }
                    }
                    .disabled(store.isBusy)
                    .accessibilityLabel(language.text("patch.add"))
                }
            }
            .sheet(isPresented: $showImporter) {
                FileDocumentPicker(
                    allowedContentTypes: PatchPackagePickerPolicy.allowedContentTypes,
                    copiesSelectedDocument: PatchPackagePickerPolicy.copiesSelectedDocument,
                    allowsMultipleSelection: false,
                    onSelection: { result in
                        showImporter = false
                        if case .success(let urls) = result, let url = urls.first {
                            store.importPackage(at: url)
                        }
                    },
                    onCancel: {
                        showImporter = false
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showCreate) {
                PatchProjectEditorView(
                    existingProject: nil
                ) { project, _ in
                    store.create(project: project)
                }
            }
            .sheet(item: $draftCoordinator.request) { request in
                PatchProjectEditorView(
                    existingProject: nil,
                    initialDraft: request.draft
                ) { project, _ in
                    store.create(project: project)
                    draftCoordinator.clear()
                }
            }
            .alert(item: $store.alert) { alert in
                Alert(
                    title: Text(language.text(alert.titleKey)),
                    message: Text(alert.message(language: language)),
                    dismissButton: .default(Text(language.text("common.ok")))
                )
            }
            .onAppear(perform: consumeExternalImport)
            .onChange(of: draftCoordinator.importRequest?.id) { _ in
                consumeExternalImport()
            }
        }
    }

    private func consumeExternalImport() {
        guard let request = draftCoordinator.importRequest else { return }
        draftCoordinator.clearImport()
        store.importPackage(from: request.source)
    }

    @ViewBuilder
    private func itemRow(_ item: PatchLibraryItem) -> some View {
        NavigationLink {
            PatchProjectDetailView(store: store, projectID: item.id)
        } label: {
            PatchProjectRow(item: item, language: language)
                .padding(14)
                .claymorphicCard(cornerRadius: 20, depth: 6)
        }
        .buttonStyle(.plain)
        .claymorphicButtonPress()
        .contextMenu {
            Button(role: .destructive) {
                store.delete(item)
            } label: {
                Label(language.text("common.delete"), systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 80, height: 80)
                    .claymorphicCircle(depth: 8)
                Image(systemName: "shippingbox")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(language.text("patch.empty_title"))
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundStyle(AppTheme.textPrimary)
            Text(language.text("patch.empty_message"))
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showCreate = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(language.text("patch.new"))
                        .font(.system(size: 14, weight: .bold, design: .default))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .claymorphicCard(cornerRadius: 16, depth: 6)
            }
            .claymorphicButtonPress()
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var searchEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppTheme.textSecondary)
            Text(language.text("patch.search_empty"))
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(AppTheme.textPrimary)
            Text(language.text("patch.search_empty_message"))
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct PatchProjectRow: View {
    let item: PatchLibraryItem
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.depressedBackground)
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(language.text(
                    item.summary.schemaVersion >= 2 ? "patch.workspace_items_count" : "patch.rules_count",
                    Int64((item.project?.rules.count ?? 0) + (item.project?.directories.count ?? 0))
                ))
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
        }
    }
}

private struct PatchProjectDetailView: View {
    @Environment(\.appLanguage) private var language
    @ObservedObject var store: PatchProjectStore
    let projectID: UUID
    @State private var showEditor = false
    @State private var editingRule: PatchRule?
    @State private var showApplyConfirmation = false
    @State private var showRestoreConfirmation = false
    @State private var isWorking = false
    @State private var actionAlert: PatchStoreAlert?
    @State private var shareRequest: PatchShareRequest?

    private var item: PatchLibraryItem? {
        store.items.first(where: { $0.id == projectID })
    }

    private var receipt: PatchTransactionReceipt? {
        DevicePatchService.latestReceipt(projectID: projectID)
    }

    private var isWorkspaceProject: Bool {
        (item?.summary.schemaVersion ?? 1) >= 2
    }

    var body: some View {
        ZStack {
            AnimatedHyperBackdrop()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    if let item, let project = item.project {
                        // Header summary card
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppTheme.depressedBackground)
                                    Image(systemName: isWorkspaceProject ? "folder.badge.gearshape" : "slider.horizontal.3")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .frame(width: 50, height: 50)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.displayName)
                                        .font(.system(size: 18, weight: .bold, design: .default))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(isWorkspaceProject ? "WORKSPACE PATCH" : "DIRECT PATCH")
                                        .font(.system(size: 10, weight: .bold, design: .default))
                                        .tracking(1.4)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                            }

                            Divider()
                                .padding(.vertical, 4)

                            if isWorkspaceProject {
                                VStack(spacing: 8) {
                                    ForEach(project.allBundleIdentifiers, id: \.self) { bundleID in
                                        HStack {
                                            Label {
                                                Text(bundleID)
                                                    .font(.system(size: 12, weight: .medium).monospaced())
                                                    .foregroundStyle(AppTheme.textPrimary)
                                            } icon: {
                                                Image(systemName: "app.dashed")
                                                    .foregroundStyle(AppTheme.accent)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .claymorphicDepression(cornerRadius: 10)
                                    }

                                    HStack {
                                        Text(language.text("patch.files"))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                        Spacer()
                                        Text("\(project.rules.count)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(AppTheme.textPrimary)
                                    }
                                    .padding(.horizontal, 4)

                                    HStack {
                                        Text(language.text("patch.folders"))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                        Spacer()
                                        Text("\(project.directories.count)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(AppTheme.textPrimary)
                                    }
                                    .padding(.horizontal, 4)

                                    if let workspaceURL = item.workspaceURL {
                                        NavigationLink {
                                            FileBrowserView(
                                                containerPath: workspaceURL.path,
                                                title: item.displayName,
                                                bundleID: nil
                                            )
                                        } label: {
                                            HStack {
                                                Image(systemName: "folder.fill")
                                                    .foregroundStyle(AppTheme.accent)
                                                Text(language.text("patch.open_workspace"))
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(AppTheme.textPrimary)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(AppTheme.textMuted)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .claymorphicDepression(cornerRadius: 12)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(project.rules) { rule in
                                        Button {
                                            editingRule = rule
                                        } label: {
                                            HStack(spacing: 10) {
                                                ruleSummary(rule)
                                                Spacer(minLength: 8)
                                                Image(systemName: "chevron.right")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(AppTheme.textMuted)
                                            }
                                            .padding(10)
                                            .claymorphicDepression(cornerRadius: 12)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityHint(language.text("patch.edit_rule_hint"))
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .claymorphicCard(cornerRadius: 24, depth: 8)

                        // Actions card
                        VStack(spacing: 12) {
                            Button {
                                showApplyConfirmation = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 15, weight: .bold))
                                    Text(language.text("patch.apply"))
                                        .font(.system(size: 14, weight: .bold, design: .default))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppTheme.activeGreen)
                                        .shadow(color: AppTheme.activeGreen.opacity(0.4), radius: 6, x: 0, y: 3)
                                )
                            }
                            .disabled(isWorking)
                            .claymorphicButtonPress()

                            if receipt != nil {
                                Button {
                                    showRestoreConfirmation = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                            .font(.system(size: 15, weight: .bold))
                                        Text(language.text("patch.restore"))
                                            .font(.system(size: 14, weight: .bold, design: .default))
                                    }
                                    .foregroundStyle(Color.red)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .claymorphicDepression(cornerRadius: 14)
                                }
                                .disabled(isWorking)
                                .claymorphicButtonPress()
                            }

                            Button(action: prepareExport) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(language.text("patch.export"))
                                        .font(.system(size: 13, weight: .bold, design: .default))
                                }
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .claymorphicDepression(cornerRadius: 14)
                            }
                            .disabled(isWorking)
                            .claymorphicButtonPress()
                        }
                        .padding(18)
                        .claymorphicCard(cornerRadius: 24, depth: 8)
                    }
                }
                .padding(.horizontal, AppTheme.pageInset)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(item?.displayName ?? language.text("patch.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isWorking {
                    ProgressView()
                } else if !isWorkspaceProject {
                    Button(language.text("patch.edit")) { showEditor = true }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.textPrimary)
                        .disabled(item?.project == nil)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let item, let project = item.project {
                PatchProjectEditorView(
                    existingProject: projectForEditor(project, displayName: item.displayName)
                ) { updatedProject, _ in
                    store.update(project: updatedProject)
                }
            }
        }
        .sheet(item: $editingRule) { rule in
            PatchRuleEditorView(rule: rule) { updatedRule in
                updateRule(updatedRule)
            }
        }
        .confirmationDialog(
            language.text("patch.apply_confirm_title"),
            isPresented: $showApplyConfirmation,
            titleVisibility: .visible
        ) {
            Button(language.text("patch.apply")) { apply() }
            Button(language.text("common.cancel"), role: .cancel) {}
        } message: {
            Text(language.text("patch.apply_confirm_message"))
        }
        .confirmationDialog(
            language.text("patch.restore_confirm_title"),
            isPresented: $showRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(language.text("patch.restore"), role: .destructive) { restore() }
            Button(language.text("common.cancel"), role: .cancel) {}
        }
        .alert(item: $actionAlert) { alert in
            Alert(
                title: Text(language.text(alert.titleKey)),
                message: Text(alert.message(language: language)),
                dismissButton: .default(Text(language.text("common.ok")))
            )
        }
        .sheet(item: $shareRequest) { request in
            PatchActivityView(items: [request.url])
                .ignoresSafeArea()
        }
    }

    private func ruleSummary(_ rule: PatchRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.bundleID)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(rule.relativePath)
                .font(.system(size: 11, weight: .medium).monospaced())
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
            Label(rule.replacementFilename, systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private func projectForEditor(_ project: PatchProject, displayName: String) -> PatchProject {
        var copy = project
        copy.name = displayName
        return copy
    }

    private func updateRule(_ updatedRule: PatchRule) {
        guard var project = item?.project,
              let index = project.rules.firstIndex(where: { $0.id == updatedRule.id }) else {
            return
        }
        project.rules[index] = updatedRule
        project.updatedAt = Date()
        do {
            try PatchPackageCodec.validate(project)
            store.update(project: project)
        } catch let error as PatchPackageError {
            actionAlert = PatchStoreAlert(
                titleKey: "common.failed",
                messageKey: error.localizationKey,
                messageArgument: error.localizationArgument
            )
        } catch {
            actionAlert = PatchStoreAlert(
                titleKey: "common.failed",
                messageKey: "patch.error.invalid_project"
            )
        }
    }

    private func apply() {
        guard let item, let baseProject = item.project else { return }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                let project = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject
                _ = try DevicePatchService.apply(project: project)
                await MainActor.run {
                    store.reload()
                    isWorking = false
                    actionAlert = PatchStoreAlert(titleKey: "common.done", messageKey: "patch.applied_message")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(titleKey: "common.failed", messageKey: "patch.error.apply")
                }
            }
        }
    }

    private func prepareExport() {
        guard let item else { return }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                if item.summary.schemaVersion >= 2 {
                    _ = try PatchProjectLibrary.synchronizeWorkspace(item: item)
                }
                await MainActor.run {
                    store.reload()
                    isWorking = false
                    shareRequest = PatchShareRequest(url: item.packageURL)
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: "patch.error.invalid_project"
                    )
                }
            }
        }
    }

    private func restore() {
        guard let receipt else { return }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(titleKey: "common.done", messageKey: "patch.restored_message")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(titleKey: "common.failed", messageKey: "patch.error.restore")
                }
            }
        }
    }
}

private struct PatchShareRequest: Identifiable {
    let id = UUID()
    let url: URL
}

private struct PatchActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
