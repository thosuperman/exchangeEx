//
//  PositionListView.swift
//  zai
//
//  Created by 渡部郷太 on 9/4/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation
import UIKit

import ZaifSwift


class PositionListView : NSObject, UITableViewDelegate, UITableViewDataSource, FundDelegate, BitCoinDelegate, PositionListViewCellDelegate {
    
    init(view: UITableView, trader: Trader) {
        self.trader = trader
        self.positions = trader.activePositions
        self.view = view
        self.view.tableFooterView = UIView()

        self.fund = Fund(api: trader.account.privateApi)
        self.bitcoin = BitCoin()
        
        super.init()
        self.view.delegate = self
        self.view.dataSource = self
        self.startWatch()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let c = self.positions.count
        return c
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "positionListViewCell", for: indexPath) as! PositionListViewCell
        let position = self.positions[(indexPath as NSIndexPath).row]
        cell.setPosition(position, btcJpyPrice: self.btcPrice)
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let cell = self.view.cellForRow(at: indexPath) as? PositionListViewCell else {
            return nil
        }
        cell.setPosition(cell.position, btcJpyPrice: self.btcPrice)
        var actions = [UITableViewRowAction]()
        if let unwind = cell.unwindAction {
            actions.append(unwind)
        }
        if let delete = cell.deleteAction {
            actions.append(delete)
        }
        if let edit = cell.editingAction {
            actions.append(edit)
        }
        if actions.count == 0 {
            let empty = UITableViewRowAction(style: .normal, title: "") { (_, _) in }
            empty.backgroundColor = UIColor.white
            return [empty]
        } else {
            return actions
        }
    }
    
    // FundDelegate    
    func recievedBtcFund(btc: Double) {
        self.btcFund = btc
    }
    
    // BitCoinDelegate
    func recievedJpyPrice(price: Int) {
        self.btcPrice = price
        for cell in self.view.visibleCells {
            let c = cell as! PositionListViewCell
            c.setPosition(c.position, btcJpyPrice: self.btcPrice)
        }
    }
    
    // PositionListViewCellDelegate
    func pushedDeleteButton(cell: PositionListViewCell, position: Position) {
        if self.trader.deletePosition(id: position.id) {
            self.positions = self.trader.allPositions
            if let index = self.view.indexPath(for: cell) {
                self.view.deleteRows(at: [index], with: UITableViewRowAnimation.fade)
            }
        }
    }
    
    func pushedEditButton(cell: PositionListViewCell, position: Position) {
        
    }
    
    func pushedUnwindButton(cell: PositionListViewCell, position: Position) {
        if let index = self.view.indexPath(for: cell) {
            self.view.reloadRows(at: [index], with: UITableViewRowAnimation.right)
        }
        self.trader.unwindPosition(id: position.id, price: nil, amount: position.balance) { (err, _) in
            if err != nil {
                position.open()
            }
            cell.setPosition(position, btcJpyPrice: self.btcPrice)
        }
    }
    
    internal func reloadData() {
        self.positions = trader.allPositions
        self.view.reloadData()
    }
    
    internal func startWatch() {
        self.fund.delegate = self
        self.bitcoin.delegate = self
        self.reloadData()
    }
    
    internal func stopWatch() {
        self.fund.delegate = nil
        self.bitcoin.delegate = nil
    }
    
    
    fileprivate var positions: [Position]
    fileprivate let view: UITableView
    fileprivate var btcPrice: Int = -1
    fileprivate var btcFund: Double = 0.0
    
    var trader: Trader! = nil
    var fund: Fund! = nil
    var bitcoin: BitCoin! = nil
}
