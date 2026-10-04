import SwiftUI

struct PatchProjectEditorView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    let existingProject: PatchProject?
    let initialDraft: PatchProjectDraft?
    let onSave: (PatchProject, String?) -> Void

    @State private var name: String
    @State private var bundleID: String
    @State private var bundleIdentifiers: [String]
    @State private var directories: [PatchDirectory]
    @State private var rules: [PatchRule]
    @State private var ruleEditor: PatchRuleEditorContext?
    @State private var validationMessageKey: String?

    init(
        existingProject: PatchProject?,
        initialDraft: PatchProjectDraft? = nil,
        onSave: @escaping (PatchProject, String?) -> Void
    ) {
        self.existingProject = existingProject
        self.initialDraft = initialDraft
        self.onSave = onSave
        _name = State(initialValue: existingProject?.name ?? initialDraft?.name ?? "")
        _bundleID = State(initialValue: initialDraft?.bundleIdentifiers.first ?? "")
        _bundleIdentifiers = State(
            initialValue: existingProject?.bundleIdentifiers
                ?? initialDraft?.bundleIdentifiers
                ?? []
        )
        _directories = State(
            initialValue: existingProject?.directories ?? initialDraft?.directories ?? []
        )
        _rules = State(initialValue: existingProject?.rules ?? initialDraft?.rules ?? [])
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedHyperBackdrop()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Project Name Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text(language.text("patch.project").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(AppTheme.textSecondary)

                            HStack(spacing: 10) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField(language.text("patch.project_name"), text: $name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .textInputAutocapitalization(.words)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .claymorphicDepression(cornerRadius: 14)
                        }
                        .padding(18)
                        .claymorphicCard(cornerRadius: 24, depth: 8)

                        // Target Bundle Section (if new)
                        if existingProject == nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(language.text("patch.target_bundle").uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(AppTheme.textSecondary)

                                if let capturedBundle = initialDraft?.bundleIdentifiers.first {
                                    HStack {
                                        Text(capturedBundle)
                                            .font(.system(size: 13, weight: .medium).monospaced())
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.textMuted)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .claymorphicDepression(cornerRadius: 14)
                                } else {
                                    HStack(spacing: 10) {
                                        Image(systemName: "app.dashed")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AppTheme.textSecondary)
                                        TextField("com.example.app", text: $bundleID)
                                            .font(.system(size: 14, weight: .medium).monospaced())
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .claymorphicDepression(cornerRadius: 14)
                                }

                                Text(language.text("patch.workspace_bundle_footer"))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .padding(.horizontal, 4)
                            }
                            .padding(18)
                            .claymorphicCard(cornerRadius: 24, depth: 8)
                        }

                        // Captured Content / Rules Section
                        if existingProject != nil || !rules.isEmpty || !directories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(language.text("patch.captured_content").uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.4)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                    if !directories.isEmpty {
                                        Text("\(directories.count) folders")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(AppTheme.textMuted)
                                    }
                                }

                                ForEach(rules) { rule in
                                    Button {
                                        ruleEditor = PatchRuleEditorContext(rule: rule)
                                    } label: {
                                        HStack(spacing: 10) {
                                            ruleRow(rule)
                                            Spacer(minLength: 8)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(AppTheme.textMuted)
                                        }
                                        .padding(12)
                                        .claymorphicDepression(cornerRadius: 14)
                                    }
                                    .buttonStyle(.plain)
                                    .claymorphicButtonPress()
                                    .accessibilityHint(language.text("patch.edit_rule_hint"))
                                }

                                if existingProject != nil {
                                    Button {
                                        ruleEditor = PatchRuleEditorContext(rule: nil)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14, weight: .bold))
                                            Text(language.text("patch.add_rule"))
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .claymorphicDepression(cornerRadius: 12)
                                    }
                                    .claymorphicButtonPress()
                                }
                            }
                            .padding(18)
                            .claymorphicCard(cornerRadius: 24, depth: 8)
                        }

                        // Validation Error Alert
                        if let validationMessageKey {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.red)
                                Text(language.text(validationMessageKey))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.red)
                                Spacer()
                            }
                            .padding(14)
                            .claymorphicDepression(cornerRadius: 14)
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.horizontal, AppTheme.pageInset)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(language.text(existingProject == nil ? "patch.new" : "patch.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.text("common.cancel")) { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text("common.done"), action: save)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .sheet(item: $ruleEditor) { context in
                PatchRuleEditorView(rule: context.rule) { savedRule in
                    if let index = rules.firstIndex(where: { $0.id == savedRule.id }) {
                        rules[index] = savedRule
                    } else {
                        rules.append(savedRule)
                    }
                }
            }
        }
    }

    private func ruleRow(_ rule: PatchRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.bundleID)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(rule.relativePath)
                .font(.system(size: 11, weight: .medium).monospaced())
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
            if rule.hasReplacement {
                Text(rule.replacementFilename)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            } else {
                Label(language.text("patch.replacement_required"), systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func save() {
        let projectName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectName.isEmpty, projectName.utf8.count <= 120 else {
            validationMessageKey = "patch.error.invalid_project"
            return
        }
        if existingProject == nil, initialDraft == nil {
            do {
                let canonical = try PatchPathValidator.canonicalBundleIdentifier(bundleID)
                guard canonical == bundleID.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    throw PatchPackageError.invalidBundleIdentifier
                }
                bundleID = canonical
                bundleIdentifiers = [canonical]
            } catch let error as PatchPackageError {
                validationMessageKey = error.localizationKey
                return
            } catch {
                validationMessageKey = "patch.error.invalid_bundle"
                return
            }
        }
        guard !bundleIdentifiers.isEmpty || !rules.isEmpty || !directories.isEmpty else {
            validationMessageKey = "patch.error.invalid_project"
            return
        }
        guard let incompleteRule = rules.first(where: { !$0.hasReplacement }) else {
            saveCompleteProject(named: projectName)
            return
        }
        validationMessageKey = "patch.error.replacement_required"
        ruleEditor = PatchRuleEditorContext(rule: incompleteRule)
    }

    private func saveCompleteProject(named projectName: String) {
        let project = PatchProject(
            id: existingProject?.id ?? UUID(),
            name: projectName,
            createdAt: existingProject?.createdAt ?? Date(),
            updatedAt: Date(),
            bundleIdentifiers: bundleIdentifiers,
            directories: directories,
            rules: rules
        )
        do {
            try PatchPackageCodec.validate(project)
            onSave(project, nil)
            dismiss()
        } catch let error as PatchPackageError {
            validationMessageKey = error.localizationKey
        } catch {
            validationMessageKey = "patch.error.invalid_project"
        }
    }
}

private struct PatchRuleEditorContext: Identifiable {
    let id = UUID()
    let rule: PatchRule?
}

struct PatchRuleEditorView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    let originalRule: PatchRule?
    let onSave: (PatchRule) -> Void

    @State private var bundleID: String
    @State private var relativePath: String
    @State private var replacementFilename: String
    @State private var replacementData: Data
    @State private var showFileImporter = false
    @State private var isImporting = false
    @State private var validationMessageKey: String?

    init(rule: PatchRule?, onSave: @escaping (PatchRule) -> Void) {
        originalRule = rule
        self.onSave = onSave
        _bundleID = State(initialValue: rule?.bundleID ?? "")
        _relativePath = State(initialValue: rule?.relativePath ?? "")
        _replacementFilename = State(initialValue: rule?.replacementFilename ?? "")
        _replacementData = State(initialValue: rule?.replacementData ?? Data())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedHyperBackdrop()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Destination Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text(language.text("patch.destination").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(AppTheme.textSecondary)

                            HStack(spacing: 10) {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField("com.example.app", text: $bundleID)
                                    .font(.system(size: 13, weight: .medium).monospaced())
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .claymorphicDepression(cornerRadius: 14)

                            HStack(spacing: 10) {
                                Image(systemName: "folder")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                TextField("Library/path/file", text: $relativePath)
                                    .font(.system(size: 13, weight: .medium).monospaced())
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .claymorphicDepression(cornerRadius: 14)

                            Text(language.text("patch.bundle_not_uuid_footer"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                                .padding(.horizontal, 4)
                        }
                        .padding(18)
                        .claymorphicCard(cornerRadius: 24, depth: 8)

                        // Replacement File Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(language.text("patch.replacement_file").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(AppTheme.textSecondary)

                            Button {
                                showFileImporter = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(AppTheme.depressedBackground)
                                        Image(systemName: replacementFilename.isEmpty ? "doc.badge.plus" : "doc.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    .frame(width: 38, height: 38)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(replacementFilename.isEmpty
                                             ? language.text("patch.choose_file")
                                             : replacementFilename)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .lineLimit(1)
                                        Text(language.text(replacementFilename.isEmpty
                                             ? "patch.replacement_required"
                                             : "patch.change_replacement"))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(replacementFilename.isEmpty ? Color.orange : AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                                .padding(12)
                                .claymorphicDepression(cornerRadius: 14)
                            }
                            .buttonStyle(.plain)
                            .claymorphicButtonPress()
                            .disabled(isImporting)

                            if isImporting {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text(language.text("patch.importing_replacement"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                .padding(.horizontal, 4)
                            }

                            if !replacementFilename.isEmpty {
                                HStack {
                                    Text(language.text("patch.file_size"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(replacementData.count), countStyle: .file))
                                        .font(.system(size: 12, weight: .bold).monospaced())
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(18)
                        .claymorphicCard(cornerRadius: 24, depth: 8)

                        // Validation Error Alert
                        if let validationMessageKey {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.red)
                                Text(language.text(validationMessageKey))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.red)
                                Spacer()
                            }
                            .padding(14)
                            .claymorphicDepression(cornerRadius: 14)
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.horizontal, AppTheme.pageInset)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(language.text(originalRule == nil ? "patch.add_rule" : "patch.edit_rule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.text("common.cancel")) { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text("common.done"), action: save)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.textPrimary)
                        .disabled(isImporting)
                }
            }
            .sheet(isPresented: $showFileImporter) {
                FileDocumentPicker(
                    allowsMultipleSelection: false,
                    onSelection: { result in
                        showFileImporter = false
                        importFile(result)
                    },
                    onCancel: {
                        showFileImporter = false
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    private func importFile(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        isImporting = true
        validationMessageKey = nil
        DispatchQueue.global(qos: .userInitiated).async {
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let values = try url.resourceValues(
                    forKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey]
                )
                guard values.isDirectory != true,
                      values.isSymbolicLink != true,
                      values.isRegularFile == true else {
                    throw PatchPackageError.invalidProject
                }
                let importedData = try Data(contentsOf: url, options: .mappedIfSafe)
                DispatchQueue.main.async {
                    replacementData = importedData
                    replacementFilename = url.lastPathComponent
                    isImporting = false
                }
            } catch let error as PatchPackageError {
                DispatchQueue.main.async {
                    validationMessageKey = error.localizationKey
                    isImporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    validationMessageKey = "patch.error.invalid_project"
                    isImporting = false
                }
            }
        }
    }

    private func save() {
        do {
            let canonicalBundle = try PatchPathValidator.canonicalBundleIdentifier(bundleID)
            let canonicalPath = try PatchPathValidator.canonicalRelativePath(relativePath)
            guard !replacementFilename.isEmpty else { throw PatchPackageError.invalidProject }
            onSave(PatchRule(
                id: originalRule?.id ?? UUID(),
                bundleID: canonicalBundle,
                relativePath: canonicalPath,
                replacementFilename: replacementFilename,
                replacementData: replacementData
            ))
            dismiss()
        } catch let error as PatchPackageError {
            validationMessageKey = error.localizationKey
        } catch {
            validationMessageKey = "patch.error.invalid_project"
        }
    }
}
