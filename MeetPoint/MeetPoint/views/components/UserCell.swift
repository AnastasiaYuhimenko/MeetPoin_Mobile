//
//  UserCell.swift
//  MeetPoint
//
//  Created by Anastasia Yukhimenko on 16.05.2026.
//

import SwiftUI
import UIKit

//struct UserCell: View {
//    let user: User
//    @State var isFriend: Bool = false
//    @State var hasOffer: Bool = true
//    
//    var body: some View {
//        ZStack {
//            VStack(alignment: .leading, spacing: 12) {
//                HStack {
//                    Text(user.userName)
//                        .font(.title)
//                    Spacer()
//                    Text(user.position.rawValue)
//                        .font(.caption)
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 5)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.appPurple, lineWidth: 1)
//                        )
//                }
//                .padding(.bottom)
//                
//                FlowLayout(spacing: 8) {
//                    ForEach(user.tags) { tag in
//                        Text(tag.rawValue)
//                            .font(.caption)
//                            .padding(.horizontal, 10)
//                            .padding(.vertical, 5)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .stroke(Color.appLightPurple, lineWidth: 1)
//                            )
//                    }
//                }
//                if let usAbout = user.about {
//                    Text(usAbout)
//                        .padding(.horizontal, 15)
//                        .padding(.vertical, 10)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.appLightPurple, lineWidth: 1)
//                        )
//                        .background(
//                            Color.appLightPurple.opacity(0.1)
//                        )
//                        .padding(.vertical)
////                        .offset(y: 20)
//                }
//                if isFriend {
//                    VStack(alignment: .leading) {
//                        Text("Контакты")
//                        HStack {
//                            VStack(alignment: .leading) {
//                                Text(user.email ?? "Не указан")
//                                    .padding(.horizontal, 10)
//                                    .padding(.vertical, 5)
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: 12)
//                                            .stroke(Color.appPurple, lineWidth: 1)
//                                    )
//                                Text("Email")
//                                    .font(.caption)
//                                    .padding(.leading, 5)
//                            }
//                            VStack(alignment: .leading) {
//                                Text(user.telegram ?? "Не указан")
//                                    .padding(.horizontal, 10)
//                                    .padding(.vertical, 5)
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: 12)
//                                            .stroke(Color.appPurple, lineWidth: 1)
//                                    )
//                                Text("Telegram")
//                                    .font(.caption)
//                                    .padding(.leading, 5)
//                            }
//                        }
//                    }
//                }
//                
//                if !hasOffer {
//                    customButton(text: !isFriend ? "Уже в друзьях" : "Добавить в друзья", action: {})
//                        .disabled(isFriend)
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                } else {
//                    HStack {
//                        Button {
//                            isFriend = true
//                            hasOffer = false
//                        } label: {
//                            ZStack {
//                                RoundedRectangle(cornerRadius: 20)
//                                    .foregroundStyle(Color.appRed)
//                                    .frame(width: 150, height: 45)
//                                Text("Отклонить")
//                                    .foregroundStyle(.white)
//                            }
//                            
//                        }
//                        .padding(.trailing, 30)
//                        Button {
//                            isFriend = true
//                            hasOffer = false
//                        } label: {
//                            ZStack {
//                                RoundedRectangle(cornerRadius: 20)
//                                    .foregroundStyle(Color.appGreen)
//                                    .frame(width: 150, height: 45)
//                                Text("Принять заявку")
//                                    .foregroundStyle(.white)
//                            }
//                            
//                        }
//                    }
////                    .padding(.vertical, 35)
////                    .offset(y: 25)
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                }
//            }
//            .padding(20)
//            //        .background(
//            //
//            //        )
//            .padding(.horizontal, 16)
//            .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color.gray.opacity(0.1))
//                .frame(width: 370, height: 370)
//            )
//        }
//    }
//}

//#Preview {
//    UserCell(user: userDevelop.user)
//}


// MARK: - PaddedLabel

final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }
}

// MARK: - TagsFlowView

final class TagsFlowView: UIView {
    private let spacing: CGFloat = 8
    private var tagViews: [UIView] = []
    private var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }

    func configure(with tags: [Tag]) {
        tagViews.forEach { $0.removeFromSuperview() }
        tagViews = tags.map { makeTagLabel($0.rawValue) }
        tagViews.forEach { addSubview($0) }
        setNeedsLayout()
    }

    private func makeTagLabel(_ text: String) -> PaddedLabel {
        let label = PaddedLabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor(named: "appLightPurple")?.cgColor ?? UIColor.purple.cgColor
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        let height = performLayout(width: bounds.width)
        if heightConstraint?.constant != height {
            heightConstraint?.constant = height
            superview?.setNeedsLayout()
        }
    }

    @discardableResult
    private func performLayout(width: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in tagViews {
            let size = (view as? PaddedLabel)?.intrinsicContentSize
                ?? view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return tagViews.isEmpty ? 0 : y + rowHeight
    }
}

// MARK: -  View

final class UserCellView: UIView {

    // MARK: State
    private(set) var isFriend = false
    private(set) var isSelf = false
    private(set) var hasOffer = true
    private var connectionState: ConnectionStatusState?

    // MARK: Card
    private let cardView = UIView()
    private let mainStack = UIStackView()

    // MARK: Header
    private let nameLabel = UILabel()
    private let positionLabel = PaddedLabel()

    // MARK: Tags
    private let tagsFlowView = TagsFlowView()

    // MARK: About
    private let aboutContainer = UIView()
    private let aboutLabel = UILabel()

    // MARK: Contacts
    private let contactsContainer = UIView()
    private let emailBadge = PaddedLabel()
    private let telegramBadge = PaddedLabel()

    // MARK: Buttons — offer state
    private let offerButtonsStack = UIStackView()
    private let declineButton = UIButton(type: .system)
    private let acceptButton = UIButton(type: .system)

    // MARK: Buttons — no-offer state
    private let addFriendStack = UIStackView()
    private let addFriendButton = UIButton(type: .system)

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Public

    func configure(
        with user: User,
        connectionState: ConnectionStatusState? = nil,
        isFriend: Bool = false,
        hasOffer: Bool = true,
        isSelf: Bool = false
    ) {
        self.isFriend = isFriend
        self.hasOffer = hasOffer
        self.isSelf = isSelf
        self.connectionState = connectionState

        nameLabel.text = user.displayName
        positionLabel.text = user.position.rawValue
        tagsFlowView.configure(with: user.tags)

        if let about = user.about {
            aboutLabel.text = about
            aboutContainer.isHidden = false
        } else {
            aboutContainer.isHidden = true
        }

        emailBadge.text = user.email ?? "Не указан"
        telegramBadge.text = user.telegram ?? "Не указан"

        refresh()
    }

    // MARK: Private — setup

    private func setup() {
        setupCard()
        setupHeader()
        setupAbout()
        setupContacts()
        setupButtons()
        assembleMainStack()
    }

    private func setupCard() {
        cardView.backgroundColor = .appCard
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupHeader() {
        nameLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        positionLabel.font = .systemFont(ofSize: 12)
        positionLabel.layer.borderWidth = 1
        positionLabel.layer.borderColor = UIColor(named: "appPurple")?.cgColor ?? UIColor.purple.cgColor
        positionLabel.layer.cornerRadius = 12
        positionLabel.clipsToBounds = true
        positionLabel.setContentHuggingPriority(.required, for: .horizontal)
        positionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupAbout() {
        aboutLabel.font = .systemFont(ofSize: 14)
        aboutLabel.numberOfLines = 0
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false

        aboutContainer.layer.borderWidth = 1
        aboutContainer.layer.borderColor = UIColor(named: "appLightPurple")?.cgColor ?? UIColor.purple.cgColor
        aboutContainer.layer.cornerRadius = 12
        aboutContainer.backgroundColor = UIColor(named: "appLightPurple")?.withAlphaComponent(0.1)
        aboutContainer.addSubview(aboutLabel)

        NSLayoutConstraint.activate([
            aboutLabel.topAnchor.constraint(equalTo: aboutContainer.topAnchor, constant: 10),
            aboutLabel.leadingAnchor.constraint(equalTo: aboutContainer.leadingAnchor, constant: 15),
            aboutLabel.trailingAnchor.constraint(equalTo: aboutContainer.trailingAnchor, constant: -15),
            aboutLabel.bottomAnchor.constraint(equalTo: aboutContainer.bottomAnchor, constant: -10),
        ])
    }

    private func setupContacts() {
        let titleLabel = UILabel()
        titleLabel.text = "Контакты"
        titleLabel.font = .systemFont(ofSize: 14)

        func makeContactStack(badge: PaddedLabel, caption: String) -> UIStackView {
            badge.font = .systemFont(ofSize: 14)
            badge.layer.borderWidth = 1
            badge.layer.borderColor = UIColor(named: "appPurple")?.cgColor ?? UIColor.purple.cgColor
            badge.layer.cornerRadius = 12
            badge.clipsToBounds = true

            let captionLabel = UILabel()
            captionLabel.text = caption
            captionLabel.font = .systemFont(ofSize: 11)
            captionLabel.textColor = .secondaryLabel

            let stack = UIStackView(arrangedSubviews: [badge, captionLabel])
            stack.axis = .vertical
            stack.spacing = 4
            stack.alignment = .leading
            return stack
        }

        let emailStack = makeContactStack(badge: emailBadge, caption: "Email")
        let telegramStack = makeContactStack(badge: telegramBadge, caption: "Telegram")

        let row = UIStackView(arrangedSubviews: [emailStack, telegramStack])
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        let contactsStack = UIStackView(arrangedSubviews: [titleLabel, row])
        contactsStack.axis = .vertical
        contactsStack.spacing = 8
        contactsStack.translatesAutoresizingMaskIntoConstraints = false

        contactsContainer.addSubview(contactsStack)
        NSLayoutConstraint.activate([
            contactsStack.topAnchor.constraint(equalTo: contactsContainer.topAnchor),
            contactsStack.leadingAnchor.constraint(equalTo: contactsContainer.leadingAnchor),
            contactsStack.trailingAnchor.constraint(equalTo: contactsContainer.trailingAnchor),
            contactsStack.bottomAnchor.constraint(equalTo: contactsContainer.bottomAnchor),
        ])
    }

    private func setupButtons() {
        // Decline
        declineButton.setTitle("Отклонить", for: .normal)
        declineButton.setTitleColor(.white, for: .normal)
        declineButton.backgroundColor = UIColor(named: "appRed") ?? .systemRed
        declineButton.layer.cornerRadius = 20
        declineButton.titleLabel?.font = .systemFont(ofSize: 16)
        declineButton.addTarget(self, action: #selector(didTapDecline), for: .touchUpInside)
        NSLayoutConstraint.activate([
            declineButton.heightAnchor.constraint(equalToConstant: 45),
            declineButton.widthAnchor.constraint(equalToConstant: 150),
        ])

        // Accept
        acceptButton.setTitle("Принять заявку", for: .normal)
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.backgroundColor = UIColor(named: "appGreen") ?? .systemGreen
        acceptButton.layer.cornerRadius = 20
        acceptButton.titleLabel?.font = .systemFont(ofSize: 16)
        acceptButton.addTarget(self, action: #selector(didTapAccept), for: .touchUpInside)
        NSLayoutConstraint.activate([
            acceptButton.heightAnchor.constraint(equalToConstant: 45),
            acceptButton.widthAnchor.constraint(equalToConstant: 150),
        ])

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        offerButtonsStack.axis = .horizontal
        offerButtonsStack.spacing = 12
        offerButtonsStack.alignment = .center
        offerButtonsStack.addArrangedSubview(spacer)
        offerButtonsStack.addArrangedSubview(declineButton)
        offerButtonsStack.addArrangedSubview(acceptButton)

        // Add friend
        addFriendButton.layer.cornerRadius = 20
        addFriendButton.backgroundColor = UIColor(named: "appYellow") ?? .systemYellow
        addFriendButton.setTitleColor(UIColor(named: "appPurple") ?? .purple, for: .normal)
        addFriendButton.setTitleColor(.lightGray, for: .disabled)
        addFriendButton.titleLabel?.font = .systemFont(ofSize: 16)
        NSLayoutConstraint.activate([
            addFriendButton.heightAnchor.constraint(equalToConstant: 50),
            addFriendButton.widthAnchor.constraint(equalToConstant: 200),
        ])

        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addFriendStack.axis = .horizontal
        addFriendStack.addArrangedSubview(spacer2)
        addFriendStack.addArrangedSubview(addFriendButton)
    }

    private func assembleMainStack() {
        let headerStack = UIStackView(arrangedSubviews: [nameLabel, positionLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center

        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        mainStack.addArrangedSubview(headerStack)
        mainStack.setCustomSpacing(20, after: headerStack)
        mainStack.addArrangedSubview(tagsFlowView)
        mainStack.addArrangedSubview(aboutContainer)
        mainStack.addArrangedSubview(contactsContainer)
        mainStack.addArrangedSubview(offerButtonsStack)
        mainStack.addArrangedSubview(addFriendStack)

        cardView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
        ])
    }

    // MARK: Private — update

    private func refresh() {
        let effectiveState: ConnectionStatusState
        if let connectionState {
            effectiveState = connectionState
        } else if isFriend {
            effectiveState = .contacts
        } else if hasOffer {
            effectiveState = .incoming(requestId: nil)
        } else {
            effectiveState = .noStatus
        }

        contactsContainer.isHidden = effectiveState != .contacts

        switch effectiveState {
        case .contacts:
            offerButtonsStack.isHidden = true
            addFriendStack.isHidden = false
            addFriendButton.setTitle("Уже в друзьях", for: .normal)
            addFriendButton.isEnabled = false
            addFriendButton.backgroundColor = .appMutedSurface
        case .incoming:
            offerButtonsStack.isHidden = false
            addFriendStack.isHidden = true
            addFriendButton.isEnabled = true
        case .outgoing:
            offerButtonsStack.isHidden = true
            addFriendStack.isHidden = false
            addFriendButton.setTitle("запрос отправлен", for: .normal)
            addFriendButton.isEnabled = false
            addFriendButton.backgroundColor = UIColor(named: "appLightPurple")
                ?? UIColor(named: "appPurple")
                ?? .appMutedSurface
        case .noStatus, .declined:
            offerButtonsStack.isHidden = true
            addFriendStack.isHidden = false
            addFriendButton.setTitle("Добавить в друзья", for: .normal)
            addFriendButton.isEnabled = true
            addFriendButton.backgroundColor = UIColor(named: "appYellow") ?? .systemYellow
        case .unknown(let raw):
            offerButtonsStack.isHidden = true
            addFriendStack.isHidden = false
            addFriendButton.setTitle("Статус: \(raw)", for: .normal)
            addFriendButton.isEnabled = false
            addFriendButton.backgroundColor = .appMutedSurface
        }

        if isSelf {
            offerButtonsStack.isHidden = true
            addFriendStack.isHidden = true
        }
    }

    // MARK: Actions

    @objc private func didTapAccept() {
        isFriend = true
        hasOffer = false
        connectionState = .contacts
        refresh()
    }

    @objc private func didTapDecline() {
        hasOffer = false
        connectionState = ConnectionStatusState.noStatus
        refresh()
    }
}

// MARK: - Preview

#Preview("Есть заявка") {
    UserCellPreview(isFriend: false, hasOffer: true)
}

#Preview("Друг (контакты видны)") {
    UserCellPreview(isFriend: true, hasOffer: false)
}

#Preview("Не друг, нет заявки") {
    UserCellPreview(isFriend: false, hasOffer: false)
}

private struct UserCellPreview: UIViewControllerRepresentable {
    var isFriend: Bool
    var hasOffer: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .appBackground

        let cell = UserCellView()
        cell.configure(with: userDevelop.user, isFriend: isFriend, hasOffer: hasOffer)
        cell.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(cell)

        NSLayoutConstraint.activate([
            cell.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cell.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            cell.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
        ])
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
