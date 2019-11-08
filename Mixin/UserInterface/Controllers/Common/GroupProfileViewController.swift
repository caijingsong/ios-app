import UIKit

final class GroupProfileViewController: ProfileViewController {
    
    override var conversationId: String {
        return conversation.conversationId
    }
    
    override var isMuted: Bool {
        return conversation.isMuted
    }
    
    private var conversation: ConversationItem
    private var codeId: String?
    private var isMember: Bool
    private var response: ConversationResponse?
    private let isAnnouncementExpanded: Bool
    
    private var participantsCount: Int?
    private var isAdmin = false
    
    init(conversation: ConversationItem, isAnnouncementExpanded: Bool) {
        self.conversation = conversation
        self.codeId = nil
        self.isMember = true
        self.isAnnouncementExpanded = isAnnouncementExpanded
        self.participantsCount = 0
        super.init(nibName: R.nib.profileView.name, bundle: R.nib.profileView.bundle)
        modalPresentationStyle = .custom
        transitioningDelegate = PopupPresentationManager.shared
        size = isAnnouncementExpanded ? .expanded : .compressed
    }
    
    init(response: ConversationResponse, codeId: String, participants: [ParticipantUser], isMember: Bool) {
        self.conversation = ConversationItem(response: response)
        self.codeId = codeId
        self.isMember = isMember
        self.isAnnouncementExpanded = false
        self.participantsCount = participants.count
        super.init(nibName: R.nib.profileView.name, bundle: R.nib.profileView.bundle)
        modalPresentationStyle = .custom
        transitioningDelegate = PopupPresentationManager.shared
        size = .compressed
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
        updatePreferredContentSizeHeight()
    }
    
    override func updateMuteInterval(inSeconds interval: Int64) {
        let conversationId = conversation.conversationId
        NotificationCenter.default.postOnMain(name: .ConversationDidChange, object: ConversationChange(conversationId: conversationId, action: .startedUpdateConversation))
        ConversationAPI.shared.mute(conversationId: conversationId, duration: interval) { [weak self] (result) in
            switch result {
            case let .success(response):
                self?.conversation.muteUntil = response.muteUntil
                self?.reloadData()
                ConversationDAO.shared.updateConversationMuteUntil(conversationId: conversationId, muteUntil: response.muteUntil)
                let toastMessage: String
                if interval == MuteInterval.none {
                    toastMessage = Localized.PROFILE_TOAST_UNMUTED
                } else {
                    let dateRepresentation = DateFormatter.dateSimple.string(from: response.muteUntil.toUTCDate())
                    toastMessage = Localized.PROFILE_TOAST_MUTED(muteUntil: dateRepresentation)
                }
                showAutoHiddenHud(style: .notification, text: toastMessage)
            case let .failure(error):
                showAutoHiddenHud(style: .error, text: error.localizedDescription)
            }
        }
    }
    
}

// MARK: - Actions
extension GroupProfileViewController {
    
    @objc func showParticipants() {
        let vc = GroupParticipantsViewController.instance(conversation: conversation)
        dismissAndPush(vc)
    }
    
    @objc func sendMessage(_ button: BusyButton) {
        guard let response = response else {
            // Currently group profile with ConversationItem is only
            // triggered by tapping on Converation's top right icon
            dismiss(animated: true, completion: nil)
            return
        }
        guard UIApplication.currentConversationId() != conversation.conversationId else {
            dismiss(animated: true, completion: nil)
            return
        }
        button.isBusy = true
        showConversation(with: response)
    }
    
    @objc func joinGroup() {
        guard let codeId = codeId, !codeId.isEmpty else {
            return
        }
        relationshipView.isBusy = true
        ConversationAPI.shared.joinConversation(codeId: codeId) { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case .success(let response):
                weakSelf.showConversation(with: response)
            case let .failure(error):
                weakSelf.relationshipView.isBusy = false
                showAutoHiddenHud(style: .error, text: error.localizedDescription)
            }
        }
    }
    
    @objc func showSharedMedia() {
        let vc = R.storyboard.chat.shared_media()!
        vc.conversationId = conversation.conversationId
        let container = ContainerViewController.instance(viewController: vc, title: R.string.localizable.chat_shared_media())
        dismissAndPush(container)
    }
    
    @objc func searchConversation() {
        let vc = InConversationSearchViewController()
        vc.load(group: conversation)
        let container = ContainerViewController.instance(viewController: vc, title: conversation.name)
        dismissAndPush(container)
    }
    
    @objc func editAnnouncement() {
        let vc = GroupAnnouncementViewController.instance(conversation: conversation)
        dismissAndPush(vc)
    }
    
    @objc func editGroupName() {
        let conversation = self.conversation
        presentEditNameController(title: Localized.CONTACT_TITLE_CHANGE_NAME, text: conversation.name, placeholder: Localized.PLACEHOLDER_NEW_NAME) { [weak self] (name) in
            NotificationCenter.default.postOnMain(name: .ConversationDidChange, object: ConversationChange(conversationId: conversation.conversationId, action: .startedUpdateConversation))
            ConversationAPI.shared.updateGroupName(conversationId: conversation.conversationId, name: name) { (result) in
                switch result {
                case .success:
                    if let self = self {
                        self.conversation.name = name
                        self.titleLabel.text = name
                    }
                case let .failure(error):
                    showAutoHiddenHud(style: .error, text: error.localizedDescription)
                }
            }
        }
    }
    
    @objc func exitGroup() {
        let conversationId = conversation.conversationId
        DispatchQueue.global().async {
            ConversationDAO.shared.makeQuitConversation(conversationId: conversationId)
            NotificationCenter.default.postOnMain(name: .ConversationDidChange, object: nil)
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    if UIApplication.currentConversationId() == conversationId {
                        UIApplication.homeNavigationController?.backToHome()
                    } else {
                        showAutoHiddenHud(style: .notification, text: R.string.localizable.action_done())
                    }
                }
            }
        }
    }
    
}

// MARK: - Private works
extension GroupProfileViewController {
    
    private func reloadData() {
        for view in centerStackView.subviews {
            view.removeFromSuperview()
        }
        
        loadAvatar()
        titleLabel.text = conversation.name
        updateSubtitle()
        
        if !isMember {
            relationshipView.style = .joinGroup
            relationshipView.button.removeTarget(nil, action: nil, for: .allEvents)
            relationshipView.button.addTarget(self, action: #selector(joinGroup), for: .touchUpInside)
            centerStackView.addArrangedSubview(relationshipView)
        }
        
        if !conversation.announcement.isEmpty {
            descriptionView.label.text = conversation.announcement
            descriptionView.label.mode = isAnnouncementExpanded ? .normal : .collapsed
            centerStackView.addArrangedSubview(descriptionView)
        }
        
        if isMember {
            shortcutView.leftShortcutButton.setImage(R.image.ic_group_member(), for: .normal)
            shortcutView.leftShortcutButton.removeTarget(nil, action: nil, for: .allEvents)
            shortcutView.leftShortcutButton.addTarget(self, action: #selector(showParticipants), for: .touchUpInside)
            shortcutView.sendMessageButton.removeTarget(nil, action: nil, for: .allEvents)
            shortcutView.sendMessageButton.addTarget(self, action: #selector(sendMessage(_:)), for: .touchUpInside)
            shortcutView.toggleSizeButton.removeTarget(nil, action: nil, for: .allEvents)
            shortcutView.toggleSizeButton.addTarget(self, action: #selector(toggleSize), for: .touchUpInside)
            centerStackView.addArrangedSubview(shortcutView)
        }
        
        updateMenuItems()
        
        let conversationId = conversation.conversationId
        DispatchQueue.global().async { [weak self] in
            let participantsCount = ParticipantDAO.shared.getParticipantCount(conversationId: conversationId)
            let isAdmin = ParticipantDAO.shared.isAdmin(conversationId: conversationId, userId: AccountAPI.shared.accountUserId)
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                self.participantsCount = participantsCount
                self.isAdmin = isAdmin
                self.updateSubtitle()
                self.updateMenuItems()
            }
        }
    }
    
    private func loadAvatar() {
        guard conversation.iconUrl.isEmpty else {
            avatarImageView.setGroupImage(conversation: conversation)
            return
        }
        
        avatarImageView.image = R.image.ic_conversation_group()
        let conversationId = conversation.conversationId
        let response = self.response
        
        DispatchQueue.global().async { [weak self] in
            
            func setIcon(participants: [ParticipantUser]) {
                guard let image = GroupIconMaker.make(participants: participants) else {
                    return
                }
                DispatchQueue.main.async {
                    self?.avatarImageView.image = image
                }
            }
            
            if let participants = response?.participants {
                let participantIds = participants.prefix(4).map { $0.userId }
                switch UserAPI.shared.showUsers(userIds: participantIds) {
                case let .success(users):
                    let participants = users.map {
                        ParticipantUser(conversationId: conversationId,
                                        role: "",
                                        userId: $0.userId,
                                        userFullName: $0.fullName,
                                        userAvatarUrl: $0.avatarUrl,
                                        userIdentityNumber: $0.identityNumber)
                    }
                    setIcon(participants: participants)
                case let .failure(error):
                    showAutoHiddenHud(style: .error, text: error.localizedDescription)
                }
            } else {
                let participants = ParticipantDAO.shared.getGroupIconParticipants(conversationId: conversationId)
                setIcon(participants: participants)
            }
        }
    }
    
    private func updateSubtitle() {
        if let count = participantsCount {
            subtitleLabel.text = Localized.GROUP_TITLE_MEMBERS(count: "\(count)")
        } else {
            subtitleLabel.text = nil
        }
    }
    
    private func updateMenuItems() {
        var groups = [[ProfileMenuItem]]()
        
        groups.append([
            ProfileMenuItem(title: R.string.localizable.chat_shared_media(),
                            subtitle: nil,
                            style: [],
                            action: #selector(showSharedMedia)),
            ProfileMenuItem(title: R.string.localizable.profile_search_conversation(),
                            subtitle: nil,
                            style: [],
                            action: #selector(searchConversation))
        ])
        
        if isAdmin {
            groups.append([
                ProfileMenuItem(title: R.string.localizable.group_menu_announcement(),
                                subtitle: nil,
                                style: [],
                                action: #selector(editAnnouncement)),
                ProfileMenuItem(title: R.string.localizable.profile_edit_name(),
                                subtitle: nil,
                                style: [],
                                action: #selector(editGroupName))
            ])
        }
        
        if conversation.isMuted {
            let subtitle: String?
            if let date = conversation.muteUntil?.toUTCDate() {
                let rep = DateFormatter.log.string(from: date)
                subtitle = R.string.localizable.profile_mute_ends_at(rep)
            } else {
                subtitle = nil
            }
            groups.append([
                ProfileMenuItem(title: R.string.localizable.profile_muted(),
                                subtitle: subtitle,
                                style: [],
                                action: #selector(mute))
            ])
        } else {
            groups.append([
                ProfileMenuItem(title: R.string.localizable.profile_mute(),
                                subtitle: nil,
                                style: [],
                                action: #selector(mute))
            ])
        }
        
        groups.append([
            ProfileMenuItem(title: R.string.localizable.group_menu_clear(),
                            subtitle: nil,
                            style: [.destructive],
                            action: #selector(clearChat)),
            ProfileMenuItem(title: R.string.localizable.group_menu_exit(),
                            subtitle: nil,
                            style: [.destructive],
                            action: #selector(exitGroup))
        ])
        
        for view in menuStackView.subviews {
            view.removeFromSuperview()
        }
        menuItemGroups = groups
    }
    
    private func showConversation(with response: ConversationResponse) {
        DispatchQueue.global().async { [weak self] in
            guard ConversationDAO.shared.createConversation(conversation: response, targetStatus: .SUCCESS), let conversation = ConversationDAO.shared.getConversation(conversationId: response.conversationId) else {
                self?.dismiss(animated: true, completion: nil)
                return
            }
            DispatchQueue.main.async {
                self?.dismiss(animated: true, completion: {
                    let vc = ConversationViewController.instance(conversation: conversation)
                    UIApplication.homeNavigationController?.pushViewController(withBackRoot: vc)
                })
            }
        }
    }
    
}
