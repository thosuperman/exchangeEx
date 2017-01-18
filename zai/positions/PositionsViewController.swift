//
//  PositionsViewController.swift
//  zai
//
//  Created by 渡部郷太 on 9/4/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation
import UIKit



class PositionsViewController : UIViewController, UITextFieldDelegate, PositionFundViewDelegate, PositionEditDelegate, PositionCreateDelegate, PositionListViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = Color.keyColor
        
        self.positionsHeaderLabel.backgroundColor = Color.keyColor2
        
        self.totalProfit.text = "-"
        self.priceAverage.text = "-"
        self.btcFund.text = "-"
        
        let account = getAccount()
        self.trader = account!.activeExchange.trader
        
        self.positionListView = PositionListView(view: self.tableView, trader: self.trader)
        self.positionListView.delegate = self
        self.positionFundView = PositionFundView(trader: self.trader)
        
        self.addPositionButton.tintColor = Color.antiKeyColor
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.positionListView.startWatch()
        self.positionListView.reloadData()
        self.positionFundView.monitoringInterval = getPositionsConfig().autoUpdateInterval
        self.positionFundView.delegate = self
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.positionListView.stopWatch()
        self.positionFundView.delegate = nil
    }
    
    @IBAction func pushAddPositionButton(_ sender: Any) {
        let addPositionController = PositionCreateViewController(trader: self.trader)
        addPositionController.delegate = self
        self.present(addPositionController.controller, animated: true, completion: nil)
    }
    
    // PositionFundViewDelegate
    func recievedTotalProfit(profit: String) {
        DispatchQueue.main.async {
            self.totalProfit.text = profit
        }
    }
    
    func recievedPriceAverage(average: String) {
        DispatchQueue.main.async {
            self.priceAverage.text = average
        }
    }
    
    func recievedBtcFund(btc: String) {
        DispatchQueue.main.async {
            self.btcFund.text = btc
        }
    }
    
    // PositionCreateDelegate
    func createOk(position: Position) {
        self.trader.addPosition(position)
        self.positionListView.addPosition(position: position)
    }
    
    func createCancel() {
        print("Creating position cancelled")
    }
    
    // PositionEditDelegate
    func editOk(position: Position) {
        
    }
    
    func editCancel() {
        print("Editing position cancelled")
    }
    
    // PositionListViewDelegate
    func editPosition(position: Position) {
        let editPositionController = PositionEditViewController(trader: self.trader, position: position)
        editPositionController.delegate = self
        self.present(editPositionController.controller, animated: true, completion: nil)
    }
    
    @IBAction func pushSettingsButton(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        let settings = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as! UINavigationController
        self.present(settings, animated: true, completion: nil)
    }
    
    var trader: Trader!
    
    var positionListView: PositionListView! = nil
    var positionFundView: PositionFundView! = nil
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var positionsHeaderLabel: UILabel!
    
    @IBOutlet weak var totalProfit: UILabel!
    @IBOutlet weak var priceAverage: UILabel!
    @IBOutlet weak var btcFund: UILabel!
    @IBOutlet weak var addPositionButton: UIBarButtonItem!
}
