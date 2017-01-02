//
//  BitCoin.swift
//  zai
//
//  Created by 渡部郷太 on 12/11/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation


@objc protocol BitCoinDelegate : MonitorableDelegate {
    @objc optional func recievedJpyPrice(price: Int)
}


internal class BitCoin : Monitorable {
    
    init(api: Api) {
        self.api = api
    }
    
    func getPriceFor(_ currency: ApiCurrency, cb: @escaping (ZaiError?, Double) -> Void) {
        switch currency {
        case ApiCurrency.JPY:
            self.api.getPrice(currencyPair: ApiCurrencyPair.BTC_JPY) { (err, price) in
                if err != nil {
                    cb(ZaiError(errorType: .ZAIF_API_ERROR, message: err!.message), 0.0)
                } else {
                    cb(nil, price)
                }
            }
        default:
            cb(ZaiError(), 0)
        }
    }
    
    func getBestAskQuote(_ currency: ApiCurrency, cb: @escaping (ZaiError?, Quote?) -> Void) {
        switch currency {
        case ApiCurrency.JPY:
            self.api.getBoard(currencyPair: ApiCurrencyPair.BTC_JPY) { (err, board) in
                if err != nil {
                    cb(ZaiError(errorType: .ZAIF_API_ERROR, message: err!.message), nil)
                } else {
                    guard let quote = board.getBestAsk() else {
                        cb(ZaiError(errorType: .ZAIF_API_ERROR), nil)
                        return
                    }
                    cb(nil, quote)
                }
            }
        default:
            cb(ZaiError(), nil)
        }
    }
    
    func getBestBidQuote(_ currency: ApiCurrency, cb: @escaping (ZaiError?, Quote?) -> Void) {
        switch currency {
        case ApiCurrency.JPY:
            self.api.getBoard(currencyPair: ApiCurrencyPair.BTC_JPY) { (err, board) in
                if err != nil {
                    cb(ZaiError(errorType: .ZAIF_API_ERROR, message: err!.message), nil)
                } else {
                    guard let quote = board.getBestBid() else {
                        cb(ZaiError(errorType: .ZAIF_API_ERROR), nil)
                        return
                    }
                    cb(nil, quote)
                }
            }
        default:
            cb(ZaiError(), nil)
        }
    }
    
    override func monitor() {
        let delegate = self.delegate as? BitCoinDelegate
        if delegate?.recievedJpyPrice != nil {
            self.getPriceFor(.JPY) { (err, price) in
                if err == nil {
                    delegate?.recievedJpyPrice?(price: Int(price))
                }
            }
        }
    }

    let api: Api
}