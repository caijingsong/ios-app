import UIKit

class SettingViewController: UITableViewController {

    @IBOutlet weak var blockedUsersDetailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateBlockedUserCell()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBlockedUserCell), name: .UserDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateBlockedUserCell() {
        DispatchQueue.global().async {
            let blocked = UserDAO.shared.getBlockUsers()
            DispatchQueue.main.async {
                if blocked.count > 0 {
                    self.blockedUsersDetailLabel.text = String(blocked.count) + Localized.SETTING_BLOCKED_USER_COUNT_SUFFIX
                } else {
                    self.blockedUsersDetailLabel.text = Localized.SETTING_BLOCKED_USER_COUNT_NONE
                }
            }
        }
    }

    class func instance() -> UIViewController {
        return ContainerViewController.instance(viewController: Storyboard.setting.instantiateInitialViewController()!, title: Localized.SETTING_TITLE)
    }
}

extension SettingViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc: UIViewController
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                vc = BlockUserViewController.instance()
            default:
                vc = ConversationSettingViewController.instance()
            }
        case 1:
            vc = AuthorizationsViewController.instance()
        case 2:
            vc = StorageUsageViewController.instance()
        case 3:
            vc = NotificationSettingsViewController.instance()
        default:
            vc = AboutContainerViewController.instance()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? Localized.SETTING_PRIVACY_AND_SECURITY_TITLE : nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? Localized.SETTING_PRIVACY_AND_SECURITY_SUMMARY : nil
    }
}
