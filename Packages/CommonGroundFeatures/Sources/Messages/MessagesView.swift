import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct MessagesView: View {
    @Query(sort: \MessageThread.lastMessageAt, order: .reverse) private var threads: [MessageThread]
    @State private var showNewThread = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if threads.isEmpty {
                    CGEmptyState(
                        icon: "bubble.left.and.bubble.right",
                        title: L10n.messagesSecureTitle,
                        message: L10n.messagesSecureDescription,
                        actionTitle: L10n.messagesStartConversation
                    ) {
                        showNewThread = true
                    }
                } else {
                    List(threads, id: \.id) { thread in
                        NavigationLink {
                            MessageThreadView(thread: thread)
                        } label: {
                            ThreadRow(thread: thread)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(L10n.messagesTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewThread = true } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewThread) {
                NewMessageThreadView()
            }
        }
    }
}

struct ThreadRow: View {
    let thread: MessageThread

    private var lastMessage: Message? {
        thread.messages.sorted(by: { $0.sentAt > $1.sentAt }).first
    }

    var body: some View {
        HStack(spacing: CGSpacing.md) {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.accentColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(thread.participantNames.joined(separator: " & "))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if thread.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                if let message = lastMessage {
                    Text(message.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(thread.lastMessageAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, CGSpacing.xxs)
    }
}

public struct MessageThreadView: View {
    let thread: MessageThread
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var families: [Family]

    @State private var newMessage = ""
    @State private var errorMessage: String?

    public init(thread: MessageThread) {
        self.thread = thread
    }

    private var sortedMessages: [Message] {
        thread.messages.sorted(by: { $0.sentAt < $1.sentAt })
    }

    private var currentMember: FamilyMember? {
        families.first?.members.first { $0.id == appState.currentMemberId }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: CGSpacing.sm) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption)
                            Text(L10n.messagesEncryptedBanner)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.vertical, CGSpacing.xs)

                        ForEach(sortedMessages, id: \.id) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(CGSpacing.md)
                }
                .onChange(of: sortedMessages.count) { _, _ in
                    if let last = sortedMessages.last {
                        withAnimation(CGAnimation.quick) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let last = sortedMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                    markRead()
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, CGSpacing.md)
            }

            messageComposer
        }
        .navigationTitle(thread.subject ?? L10n.messagesTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var messageComposer: some View {
        HStack(spacing: CGSpacing.sm) {
            TextField(L10n.messagesPlaceholder, text: $newMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(CGSpacing.sm)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: CGRadius.lg))

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(newMessage.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Color.accentColor)
            }
            .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(CGSpacing.md)
        .background(.bar)
    }

    private func sendMessage() {
        guard let sender = currentMember else {
            errorMessage = L10n.messagesAccountError
            return
        }
        errorMessage = nil
        do {
            _ = try MessagingService.sendMessage(
                context: modelContext,
                thread: thread,
                content: newMessage,
                sender: sender
            )
            newMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markRead() {
        guard let readerId = appState.currentMemberId else { return }
        try? MessagingService.markThreadRead(thread: thread, readerId: readerId, context: modelContext)
    }
}

struct MessageBubble: View {
    let message: Message
    @Environment(AppState.self) private var appState

    private var isFromCurrentUser: Bool {
        message.senderId == appState.currentMemberId
    }

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Text(message.content)
                    .font(.subheadline)
                    .padding(CGSpacing.sm)
                    .background(
                        isFromCurrentUser ? Color.accentColor : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: CGRadius.lg, style: .continuous)
                    )
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)

                HStack(spacing: 4) {
                    Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if message.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}
