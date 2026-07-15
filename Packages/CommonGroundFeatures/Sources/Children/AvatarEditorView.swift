import SwiftUI
import PhotosUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

struct AvatarEditorView: View {
    @Bindable var child: Child
    @Environment(\.dismiss) private var dismiss

    @State private var showGenmojiPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    private let emojiOptions = ["🧒", "👧", "👦", "🌟", "🦋", "🌈", "⚽️", "🎨", "📚", "🐶"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CGSpacing.lg) {
                    CGAvatar(
                        name: child.firstName,
                        imageData: child.photoData,
                        genmojiData: child.genmojiData,
                        emoji: child.avatarEmoji,
                        size: 120
                    )
                    .padding(.top, CGSpacing.md)

                    VStack(spacing: CGSpacing.sm) {
                        Button {
                            showGenmojiPicker = true
                        } label: {
                            Label(L10n.avatarGenmoji, systemImage: "face.smiling.inverse")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CGColor.primary)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label(L10n.avatarChoosePhoto, systemImage: "photo")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if child.photoData != nil || child.genmojiData != nil {
                            Button(L10n.avatarRemove, role: .destructive) {
                                child.photoData = nil
                                child.genmojiData = nil
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, CGSpacing.md)

                    VStack(alignment: .leading, spacing: CGSpacing.sm) {
                        Text(L10n.avatarPickEmoji)
                            .font(CGTypography.captionEmphasis)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, CGSpacing.md)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: CGSpacing.sm) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    child.avatarEmoji = emoji
                                    child.photoData = nil
                                    child.genmojiData = nil
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, CGSpacing.sm)
                                        .background(
                                            child.avatarEmoji == emoji && child.genmojiData == nil && child.photoData == nil
                                                ? AnyShapeStyle(CGGradient.aurora.opacity(0.2))
                                                : AnyShapeStyle(CGColor.elevatedSurface),
                                            in: RoundedRectangle(cornerRadius: CGRadius.md, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, CGSpacing.md)
                    }
                }
                .padding(.bottom, CGSpacing.xl)
            }
            .background(CGColor.canvas)
            .navigationTitle(L10n.avatarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                }
            }
            .sheet(isPresented: $showGenmojiPicker) {
                CGGenmojiPickerSheet(imageContent: $child.genmojiData)
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        child.photoData = data
                        child.genmojiData = nil
                    }
                }
            }
            .onChange(of: child.genmojiData) { _, data in
                if data != nil {
                    child.photoData = nil
                }
            }
        }
    }
}

struct MemberAvatarEditorView: View {
    @Bindable var member: FamilyMember
    @Environment(\.dismiss) private var dismiss

    @State private var showGenmojiPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: CGSpacing.lg) {
                CGAvatar(
                    name: member.displayName,
                    genmojiData: member.genmojiData,
                    emoji: member.avatarEmoji,
                    size: 120
                )
                .padding(.top, CGSpacing.xl)

                Text(L10n.avatarMemberHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CGSpacing.lg)

                Button {
                    showGenmojiPicker = true
                } label: {
                    Label(L10n.avatarMemberGenmoji, systemImage: "face.smiling.inverse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CGColor.primary)
                .padding(.horizontal, CGSpacing.md)

                if member.genmojiData != nil {
                    Button(L10n.avatarMemberRemove, role: .destructive) {
                        member.genmojiData = nil
                    }
                }

                Spacer()
            }
            .background(CGColor.canvas)
            .navigationTitle(member.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                }
            }
            .sheet(isPresented: $showGenmojiPicker) {
                CGGenmojiPickerSheet(imageContent: $member.genmojiData)
            }
        }
    }
}
