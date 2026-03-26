// Features/Swiper/CollectionPickerSheet.swift
// SlangCheck
//
// Centered floating card overlay for selecting or creating a collection for the current term.
// Displayed as a ZStack overlay within SwiperView (not a sheet).

import SwiftUI

// MARK: - CollectionPickerCard

/// Floating centered card with an embedded NavigationStack.
/// Root: collection list. "Add new" pushes NewCollectionCard.
struct CollectionPickerCard: View {

    @Bindable var viewModel: SwiperViewModel
    @Binding var isPresented: Bool
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            pickerContent
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(SlangColor.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "collections.picker.close",
                                      defaultValue: "Close")) {
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(SlangColor.primary)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(String(localized: "collections.picker.addNew",
                                      defaultValue: "Add new")) {
                            path.append("new")
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(SlangColor.primary)
                    }
                }
                .navigationDestination(for: String.self) { _ in
                    NewCollectionCard(viewModel: viewModel, isPresented: $isPresented)
                }
        }
        .frame(height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.26), radius: 12, x: 0, y: 0)
        .shadow(color: .black.opacity(0.06), radius: 92, x: 0, y: 0)
    }

    // MARK: - Picker Content

    private var pickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "collections.picker.title", defaultValue: "Collections"))
                .font(.custom("NoticiaText-Bold", size: 24))
                .foregroundStyle(.primary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.xs)
                .padding(.bottom, SlangSpacing.sm)

            ScrollView {
                LazyVStack(spacing: SlangSpacing.xs) {
                    ForEach(viewModel.collections) { collection in
                        collectionRow(collection)
                    }
                }
                .padding(.horizontal, SlangSpacing.md)
                .padding(.bottom, SlangSpacing.sm)
            }
        }
        .background(SlangColor.background)
    }

    // MARK: - Collection Row

    private func collectionRow(_ collection: SlangCollection) -> some View {
        let termID = viewModel.cardQueue.first?.id
        let isInCollection = termID.map { collection.termIDs.contains($0) } ?? false

        return Button {
            if let id = termID {
                viewModel.toggleTermInCollection(collection.id, termID: id)
            }
        } label: {
            HStack(spacing: SlangSpacing.md) {
                Text(collection.name)
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isInCollection ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(isInCollection ? SlangColor.primary : Color(.tertiaryLabel))
                    .animation(.easeInOut(duration: 0.15), value: isInCollection)
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.vertical, SlangSpacing.md)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NewCollectionCard

/// Pushed onto the NavigationStack when "Add new" is tapped.
private struct NewCollectionCard: View {

    @Bindable var viewModel: SwiperViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @FocusState private var isFocused: Bool

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: SlangSpacing.sm) {
                Text(String(localized: "collections.new.title", defaultValue: "New collection"))
                    .font(.custom("NoticiaText-Bold", size: 24))
                    .foregroundStyle(.primary)

                Text(String(localized: "collections.new.subtitle",
                            defaultValue: "Enter a name for your new collection. You can rename it later."))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextField(
                    String(localized: "collections.new.placeholder", defaultValue: "My new collection"),
                    text: $name
                )
                .focused($isFocused)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { saveIfValid() }
                .padding(.horizontal, SlangSpacing.md)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                )
                .padding(.top, SlangSpacing.xs)
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.top, SlangSpacing.md)

            Spacer(minLength: 0)

            // Save button — OnboardingCTAButton style
            Button { saveIfValid() } label: {
                Text(String(localized: "collections.new.save", defaultValue: "Save"))
                    .font(.custom("NoticiaText-Bold", size: 18))
                    .foregroundStyle(Color(.label))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(isValid
                                  ? SlangColor.onboardingTeal
                                  : SlangColor.onboardingTeal.opacity(0.4))
                            .shadow(color: .black.opacity(isValid ? 0.65 : 0), radius: 0, x: 0, y: 4)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.md)
            .animation(.easeOut(duration: 0.15), value: isValid)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SlangColor.background)
        .ignoresSafeArea(.keyboard)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SlangColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(0.45))
                isFocused = true
            }
        }
    }

    private func saveIfValid() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.createCollection(name: trimmed)
        isPresented = false
    }
}

// MARK: - Preview

#Preview("CollectionPickerCard") {
    let env = AppEnvironment.preview()
    let vm = SwiperViewModel(
        repository: env.slangTermRepository,
        hapticService: env.hapticService
    )
    return ZStack {
        SlangColor.background.ignoresSafeArea()
        CollectionPickerCard(viewModel: vm, isPresented: .constant(true))
            .padding(.horizontal, 28)
    }
}
