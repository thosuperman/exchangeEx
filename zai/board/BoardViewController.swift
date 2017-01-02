//
//  MainViewController.swift
//  zai
//
//  Created by 渡部郷太 on 6/25/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation

import ZaifSwift

class BoardViewController: UIViewController, FundDelegate, BitCoinDelegate, BoardDelegate, BoardViewDelegate, PositionDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let account = getAccount()!
        self.trader = account.activeExchange.trader
        
        self.askMomentumBar.backgroundColor = Color.askQuoteColor
        self.bidMomentumBar.backgroundColor = Color.bidQuoteColor
        
        self.boardView = BoardView(view: self.boardTableView)
        self.boardView.delegate = self
        
        self.jpyFundLabel.text = "-"
        
        self.bitcoin = BitCoin(api: account.activeExchange.api)
        self.board = Board()
        self.fund = Fund(api: account.activeExchange.api)
        self.fund.getBtcFund() { (err, btc) in
            if err == nil {
                self.btcFund = btc
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        self.board.delegate = self
        self.bitcoin.delegate = self
        self.fund.delegate = self
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.board.delegate = nil
        self.bitcoin.delegate = nil
        self.fund.delegate = nil
    }
    
    // FundDelegate
    func recievedJpyFund(jpy: Int) {
        DispatchQueue.main.async {
            self.jpyFundLabel.text = jpy.description
        }
    }
    
    func recievedBtcFund(btc: Double) {
        self.btcFund = btc
    }
    
    // BoardDelegate
    func recievedBoard(err: ZaiErrorType?, board: Board?) {
        if let _ = err {
            /*
            DispatchQueue.main.async {
                self.messageLabel.text = "Failed to connect to Zaif"
                self.messageLabel.textColor = UIColor.red
            }*/
        } else {
            self.boardView.update(board: board!)
            let askMomentum = board!.calculateAskMomentum()
            let bidMomentum = board!.calculateBidMomentum()
            let askWidth = askAmountMomentumLabel.layer.bounds.width
            let ratio = bidMomentum / askMomentum
            let bidWidth = CGFloat(Double(askWidth) * (ratio) * 0.5)
            self.bidMomentumWidth.constant = min(bidWidth, askWidth)
        }
    }
    
    // PositionDelegate
    func opendPosition(position: Position) {
        /*
        DispatchQueue.main.async {
            self.messageLabel.text = "Promised. Price: " + formatValue(Int(position.price)) + " Amount: " + formatValue(position.balance)
            self.messageLabel.textColor = UIColor(red: 0.7, green: 0.4, blue: 0.4, alpha: 1.0)
        }*/
    }
    
    func unwindPosition(position: Position) {
        /*
        DispatchQueue.main.async {
            guard let log = position.lastTrade else {
                return
            }
            self.messageLabel.text = "Promised. Price: " + formatValue(Int(log.price)) + " Amount: " + formatValue(log.amount.doubleValue)
            self.messageLabel.textColor = UIColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0)
        }*/
    }
    
    func closedPosition(position: Position) {
        /*
        DispatchQueue.main.async {
            guard let log = position.lastTrade else {
                return
            }
            self.messageLabel.text = "Promised. Price: " + formatValue(Int(log.price)) + " Amount: " + formatValue(log.amount.doubleValue)
            self.messageLabel.textColor = UIColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0)
        }*/
    }
    
    func orderBuy(quote: Quote) {
        let amt = min(quote.amount, 1.0)
        self.trader!.createLongPosition(.BTC_JPY, price: quote.price, amount: amt) { (err, position) in
            if let e = err {
                print(e.message)
            } else {
                position?.delegate = self
            }
        }
    }
    
    func orderSell(quote: Quote) {
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.config.sellMaxProfitPosition {
            self.trader.unwindMaxProfitPosition(price: quote.price, amount: quote.amount) { (err, position) in
                if err != nil {
                    position?.delegate = self
                }
            }
        } else {
            self.trader.unwindMinProfitPosition(price: quote.price, amount: quote.amount) { (err, position) in
                if err != nil {
                    position?.delegate = self
                }
            }
        }
    }

    
    var trader: Trader!

    fileprivate var currentTraderName: String = ""
    var boardView: BoardView! = nil
    
    fileprivate var fund: Fund!
    fileprivate var bitcoin: BitCoin!
    fileprivate var btcFund: Double = 0.0
    
    fileprivate var board: Board!
    
    @IBOutlet weak var boardTableView: UITableView!
    
    @IBOutlet weak var jpyFundLabel: UILabel!

    @IBOutlet weak var askMomentumBar: UILabel!
    @IBOutlet weak var bidMomentumBar: UILabel!
    @IBOutlet weak var askAmountMomentumLabel: UILabel!
    @IBOutlet weak var bidMomentumWidth: NSLayoutConstraint!

}