//
//  TemplateController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 12/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit

class TemplateController: UIViewController, ToastAlertViewPresentable {
    
    var toast: ToastAlertView?

    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var bottomTabbarView: CustomTabBar!
    @IBOutlet weak var bottomTabbarDownConstraint: NSLayoutConstraint!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBAction func addAction(_ sender: Any) {
    }
    
    @IBAction func closeAction(_ sender: Any) {
    }

    @IBAction func backAction(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.selectIndex(0)
        bottomTabbarView.onTap = { index in
            print("tabbartapped \(index)")
        }
        //addButton.isHidden = true
        closeButton.isHidden = true
        backButton.isHidden = true
        noDataView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toast?.showToastAlert("Start fetching", type: .validatePending, dismissable: false)
        loadingView.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.toast?.hideToastAlert() {
                self.toast?.showToastAlert("Done fetching", type: .info, dismissable: true)
                self.loadingView.stopAnimating()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CollectDataSegue" {
            let dest = segue.destination as? TemplateCollectController
            dest?.onCollectDataComplete = { data in
                print("Collected: ", data?.field1 ?? "Collected: nada")
            }
        }
    }
}

extension TemplateController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Template1CellID", for: indexPath) as! Template1Cell
        cell.stateView.currentState = .active
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Template1HeaderCellID") as? Template1HeaderCell
        cell?.updateCell(sectionIndex: section)
        cell?.onTap = { section in
            print("Tapped header \(section)")
        }
        return cell
    }
}

extension TemplateController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Tapped item \(indexPath.item)")
    }
}
