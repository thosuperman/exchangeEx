//
//  OrdersViewController.swift
//  zai
//
//  Created by Kyota Watanabe on 12/24/16.
//  Copyright © 2016 Kyota Watanabe. All rights reserved.
//

import Foundation
import UIKit


class OrdersViewController : UIViewController, OrderListViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = Color.keyColor
        
        self.ordersHeadersLabel.backgroundColor = Color.keyColor2
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let account = getAccount()
        self.orderListView = OrderListView(view: self.orderTableView, trader: account!.activeExchange.trader)
        self.orderListView.delegate = self
        self.orderListView.startWatch()
        self.orderListView.reloadData()
        
        if let trader = getAccount()?.activeExchange.trader {
            trader.fund.delegate = nil
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.orderListView.stopWatch()
    }
    
    @IBAction func pushSettingsButton(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        let settings = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as! UINavigationController
        self.present(settings, animated: true, completion: nil)
    }
    
    // OrderListViewDelegate
    func error(error: ZaiError) {
        let errorView = createErrorModal(title: error.errorType.toString(), message: error.message)
        self.present(errorView, animated: false, completion: nil)
    }
    
    var account: Account?
    var orderListView: OrderListView!
    
    @IBOutlet weak var ordersHeadersLabel: UILabel!
    @IBOutlet weak var orderTableView: UITableView!
}
