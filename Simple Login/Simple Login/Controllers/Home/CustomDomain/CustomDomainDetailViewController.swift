//
//  CustomDomainDetailViewController.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 19/01/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import UIKit

final class CustomDomainDetailViewController: BaseApiKeyViewController {
    @IBOutlet private weak var tableView: UITableView!

    var customDomain: CustomDomain!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        title = customDomain.name
    }

    private func setUpUI() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorColor = .clear

        DomainInfoTableViewCell.register(with: tableView)
        NotVerifiedDomainTableViewCell.register(with: tableView)
        DeleteDomainTableViewCell.register(with: tableView)
        DomainCatchAllTableViewCell.register(with: tableView)
    }

    private func showConfirmDeletionAlert() {
        let alert = UIAlertController(
            title: "Please confirm",
            message: "You are about to delete domain \"\(customDomain.name)\" from SimpleLogin",
            preferredStyle: .alert)

        let deleteAction =
            UIAlertAction(title: "Yes, delete this domain", style: .destructive) { [unowned self] _ in
            self.deleteDomain()
        }
        alert.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func deleteDomain() {
    }
}

// MARK: - UITableViewDataSource
extension CustomDomainDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = DomainInfoTableViewCell.dequeueFrom(tableView, forIndexPath: indexPath)
            cell.bind(with: customDomain)
            return cell

        case 1:
            if customDomain.isVerified {
                let cell = DomainCatchAllTableViewCell.dequeueFrom(tableView, forIndexPath: indexPath)

                cell.didSwitch = { isOn in
                    print(isOn)
                }

                cell.bind(with: customDomain)

                return cell
            } else {
                let cell = NotVerifiedDomainTableViewCell.dequeueFrom(tableView, forIndexPath: indexPath)

                cell.didTapVerifyButton = { [unowned self] in
                    // swiftlint:disable:next line_length
                    if let url = URL(string: "\(SLApiService.shared.baseUrl)/dashboard/domains/\(self.customDomain.id)/dns") {
                        UIApplication.shared.open(url)
                    }
                }

                return cell
            }

        case 2:
            let cell = DeleteDomainTableViewCell.dequeueFrom(tableView, forIndexPath: indexPath)

            cell.didTapDeleteButton = { [unowned self] in
                self.showConfirmDeletionAlert()
            }

            return cell

        default: return UITableViewCell()
        }
    }
}
