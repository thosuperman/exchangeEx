//
//  LongPosition.swift
//  
//
//  Created by 渡部郷太 on 8/31/16.
//
//

import Foundation
import CoreData

import ZaifSwift


@objc(LongPosition)
class LongPosition: Position {
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init?(order: BuyOrder, trader: Trader) {
        self.init(entity: TraderRepository.getInstance().longPositionDescription, insertIntoManagedObjectContext: nil)
        
        if !order.isPromised {
            return nil
        }

        self.id = NSUUID().UUIDString
        self.trader = trader
        self.buyLog = TradeLog(action: .OPEN_LONG_POSITION, traderName: trader.name, account: trader.account, order: order, positionId: self.id)
        self.sellLogs = []
    }
    
    override internal var balance: Double {
        get {
            var balance = self.buyLog.amount.doubleValue
            for log in self.sellLogs {
                balance -= log.amount.doubleValue
            }
            return balance
        }
    }
    
    override internal var profit: Double {
        get {
            var profit = 0.0
            for log in self.sellLogs {
                profit += log.price.doubleValue
            }
            profit -= self.buyLog.price.doubleValue
            return profit
        }
    }
    
    override internal func unwind(amount: Double?=nil, price: Double?, cb: (ZaiError?) -> Void) {
        let balance = self.balance
        var amt = amount
        if amount == nil {
            // close this position completely
            amt = balance
        }
        if balance < amt {
            amt = balance
        }
        
        let order = SellOrder(
            currencyPair: CurrencyPair(rawValue: self.buyLog.currencyPair)!,
            price: price,
            amount: amt!,
            api: self.trader.account.privateApi)!
        
        order.excute() { (err, res) in
            if let _ = err {
                cb(err)
            } else {
                order.waitForPromise() { (err, promised) in
                    if promised {
                        let log = TradeLog(action: .UNWIND_LONG_POSITION, traderName: self.trader.name, account: self.trader.account, order: order, positionId: self.id)
                        self.sellLogs.append(log)
                        cb(nil)
                    } else {
                        cb(err)
                    }
                }
            }
        }
    }
    
    private var buyLog: TradeLog! = nil
    private var sellLogs: [TradeLog]! = nil
}
