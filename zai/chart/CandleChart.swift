//
//  CandleChart.swift
//  zai
//
//  Created by Kyota Watanabe on 1/4/17.
//  Copyright © 2017 Kyota Watanabe. All rights reserved.
//

import Foundation
import UIKit


struct Trade {
    let id: String
    let price: Double
    let amount: Double
    let currencyPair: String
    let action: String
    let timestamp: Int64
}

struct Tick {
    
    init(lastPrice: Double, highPrice: Double, lowPrice: Double, vwap: Double, volume: Double, bid: Double, ask: Double) {
        self.lastPrice = lastPrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.vwap = vwap
        self.volume = volume
        self.bid = bid
        self.ask = ask
    }
    
    init() {
        self.init(lastPrice: 0.0, highPrice: 0.0, lowPrice: 0.0, vwap: 0.0, volume: 0.0, bid: 0.0, ask: 0.0)
    }
    
    let lastPrice: Double
    let highPrice: Double
    let lowPrice: Double
    let vwap: Double
    let volume: Double
    let bid: Double
    let ask: Double
}


class Candle {
    init(startDate: Int64, endDate: Int64, bollinger: Bollinger) {
        self.startDate = startDate
        self.endDate = endDate
        self.totalAverage = bollinger.ave
        self.sigmasLower = [Double]()
        self.sigmasUpper = [Double]()
        self.sigmasLower.append(bollinger.sigma1Lower)
        self.sigmasLower.append(bollinger.sigma2Lower)
        self.sigmasLower.append(bollinger.sigma3Lower)
        self.sigmasUpper.append(bollinger.sigma1Upper)
        self.sigmasUpper.append(bollinger.sigma2Upper)
        self.sigmasUpper.append(bollinger.sigma3Upper)

        self.trades = [Trade]()
    }
    
    func add(trade: Trade) -> Bool {
        if trade.timestamp < self.startDate || self.endDate <= trade.timestamp {
            return false
        }
        self.trades.append(trade)
        return true
    }
    
    func getSigmaUpper(level: Int) -> Double {
        if level < 0 || self.sigmasUpper.count < level {
            return 0.0
        }
        return self.sigmasUpper[level - 1]
    }
    
    func getSigmaLower(level: Int) -> Double {
        if level < 0 || self.sigmasLower.count < level {
            return 0.0
        }
        return self.sigmasLower[level - 1]
    }
    
    var isEmpty: Bool {
        get {
            return self.trades.count == 0
        }
    }
    
    var isBull: Bool {
        get {
            return self.openPrice! < self.lastPrice!
        }
    }
    
    var isBear: Bool {
        get {
            return self.lastPrice! < self.openPrice!
        }
    }
    
    var isCalm: Bool {
        get {
            return self.openPrice! == self.lastPrice!
        }
    }
    
    var openPrice: Double? {
        get {
            return self.trades.first?.price
        }
    }
    
    var lastPrice: Double? {
        get {
            return self.trades.last?.price
        }
    }
    
    var highPrice: Double? {
        get {
            if self.trades.count == 0 {
                return nil
            }
            var max: Double? = nil
            for trade in self.trades {
                guard let m = max else {
                    max = trade.price
                    continue
                }
                if m < trade.price {
                    max = trade.price
                }
            }
            return max!
        }
    }
    
    var lowPrice: Double? {
        get {
            if self.trades.count == 0 {
                return nil
            }
            var min: Double? = nil
            for trade in self.trades {
                guard let m = min else {
                    min = trade.price
                    continue
                }
                if trade.price < m {
                    min = trade.price
                }
            }
            return min!
        }
    }
    
    var priceAevrage: Double? {
        get {
            if self.trades.count == 0 {
                return nil
            }
            var sum = 0.0
            for trade in self.trades {
                sum += trade.price
            }
            return sum / Double(self.trades.count)
        }
    }
    
    
    var startDate: Int64
    var endDate: Int64
    var totalAverage: Double
    var sigmasUpper: [Double]
    var sigmasLower: [Double]
    var trades: [Trade]
}


protocol CandleChartDelegate : MonitorableDelegate {
    func recievedChart(chart: CandleChart, newCandles: [Candle], chartName: String)
}


class CandleChart : Monitorable {
    init(chartName: String, currencyPair: ApiCurrencyPair, interval: ChandleChartType, candleCount: Int, api: Api) {
        self.chartName = chartName
        self.currencyPair = currencyPair
        self.interval = interval
        self.candleCount = candleCount
        self.api = api
        self.candles = [Candle]()
        
        super.init(target: "Candle")
        
        self.switchInterval(interval: interval)
    }
    
    open var lastCandle: Candle? {
        return self.candles.last
    }
    
    open func switchInterval(interval: ChandleChartType) {
        if self.interval == interval {
            return
        }
        
        let now = Int64(Date().timeIntervalSince1970)
        let period = self.calculatePeriod(date: now)
        var startDate = period.0
        var endDate = period.1
        
        let oldCandles = self.candles
        self.candles = [Candle]()
        self.bollinger.clear()
        
        for _ in 0 ..< self.candleCount {
            let candle = Candle(startDate: startDate, endDate: endDate, bollinger: self.bollinger)
            self.candles.append(candle)
            startDate -= interval.seconds
            endDate -= interval.seconds
        }
        self.candles = self.candles.reversed()
        
        for candle in oldCandles {
            for trade in candle.trades {
                let _ = self.addTrade(trade: trade)
            }
        }
    }
    
    open func addTrade(trade: Trade) -> [Candle] {
        var newCandles = [Candle]()
        
        if self.candles.count == 0 {
            let candle = self.makeCandle(trade: trade)
            self.candles.append(candle)
            newCandles.append(candle)
            return newCandles
        }
        
        if trade.timestamp < self.candles.first!.startDate {
            return newCandles
        } else if self.candles.last!.endDate < trade.timestamp {
            let candle = self.makeCandle(trade: trade)
            let blankPeriodCount = (candle.startDate - self.candles.last!.endDate) / self.interval.seconds
            for _ in 0 ..< blankPeriodCount {
                self.addNextBlankPeriod()
                newCandles.append(self.lastCandle!)
            }
            if self.candles.count >= self.candleCount {
                self.candles.removeFirst()
            }
            self.candles.append(candle)
            newCandles.append(candle)
            return newCandles
        } else {
            for candle in self.candles {
                if candle.add(trade: trade) {
                    return newCandles
                }
            }
            return newCandles
        }
    }
    
    open func isGappedUp() -> Bool {
        let count = self.candles.count
        if self.candles.count < 2 {
            return false
        }
        let last = self.candles.last!
        let prev = self.candles[count - 2]
        return prev.lastPrice! < last.openPrice!
    }
    
    open func isCotinuousUp() -> Bool {
        let count = self.candles.count
        if self.candles.count < 2 {
            return false
        }
        let last = self.candles.last!
        let prev = self.candles[count - 2]
        if prev.isBull {
            return prev.lastPrice! <= last.openPrice!
        } else if prev.isBear {
            return prev.openPrice! <= last.openPrice!
        } else {
            return false
        }
    }
    
    fileprivate func addNextBlankPeriod() {
        if let last = self.candles.last {
            if let ave = last.priceAevrage {
                self.bollinger.add(sample: ave)
            }
        }
        let naxtStartDate = self.candles.last!.endDate
        let candle = Candle(startDate: naxtStartDate, endDate: naxtStartDate + self.interval.seconds, bollinger: self.bollinger)
        if self.candles.count >= self.candleCount {
            self.candles.removeFirst()
        }
        self.candles.append(candle)
    }
    
    fileprivate func makeCandle(trade: Trade) -> Candle{
        if let last = self.candles.last {
            if let ave = last.priceAevrage {
                self.bollinger.add(sample: ave)
            }
        }
        let period = self.calculatePeriod(date: trade.timestamp)
        let candle = Candle(startDate: period.0, endDate: period.1, bollinger: self.bollinger)
        let _ = candle.add(trade: trade)
        return candle
    }
    
    open var average: Double {
        get {
            var sum = 0.0
            var validCount = 0.0
            for candle in self.candles {
                if candle.isEmpty == false {
                    sum += ((candle.highPrice! + candle.lowPrice!) / 2)
                    validCount += 1.0
                }
            }
            return sum / validCount
        }
    }
    
    fileprivate func calculatePeriod(date: Int64) -> (Int64, Int64) {
        let startDate = date - (date % Int64(self.interval.seconds))
        let endDate = startDate + self.interval.seconds
        return (startDate, endDate)
    }
    
    override func monitor() {
        guard let delegate = self.delegate as? CandleChartDelegate else {
            return
        }
        
        self.getTreades() { trades in
            if trades.count == 0 {
                return
            }
            var newCandles = [Candle]()
            for trade in trades {
                if self.lastTradeId == trade.id {
                    break
                }
                newCandles = self.addTrade(trade: trade)
            }
            if trades.last!.id != "" {
                self.lastTradeId = trades.last!.id
            }

            DispatchQueue.main.async {
                delegate.recievedChart(chart: self, newCandles: newCandles, chartName: self.chartName)
            }
        }
    }
    
    fileprivate func getTreades(callback: @escaping ([Trade]) -> Void) {
        if self.isHeighPrecision {
            self.api.getTrades(currencyPair: self.currencyPair) { (err, trades) in
                if err != nil {
                    return
                }
                callback(trades)
            }
            self.isHeighPrecision = false
        } else {
            self.api.getPrice(currencyPair: self.currencyPair) { (err, price) in
                if err != nil {
                    return
                }
                let trade = Trade(id: "", price: price, amount: 0.0, currencyPair: self.currencyPair.rawValue, action: "bid", timestamp: Int64(Date().timeIntervalSince1970))
                callback([trade])
            }
        }
    }
    
    let api: Api
    let chartName: String
    let currencyPair: ApiCurrencyPair
    let interval: ChandleChartType
    let candleCount: Int
    var candles: [Candle]
    var isHeighPrecision = true
    var lastTradeId = String()
    var bollinger = Bollinger(size: 20)
}

struct ChartColors {
    let askColor: UIColor
    let bidColor: UIColor
}


class CandleChartContainer {
    init(exchanges: [Exchange], currencyPair: ApiCurrencyPair, interval: ChandleChartType, candleCount: Int) {
        self.charts = [String:CandleChart]()
        self.chartColors = [String:ChartColors]()
        
        for exchange in exchanges {
            let chart = CandleChart(chartName: exchange.name, currencyPair: currencyPair, interval: interval, candleCount: candleCount, api: exchange.api)
            
            self.chartColors[exchange.name] = CandleChartContainer.availableColors[0]
            self.charts[exchange.name] = chart
        }
    }
    
    func activateChart(chartName: String, interval: UpdateInterval, delegate: CandleChartDelegate) {
        for (name, chart) in self.charts {
            if name == chartName {
                chart.monitoringInterval = interval
                chart.delegate = delegate
            }
        }
    }
    
    func deactivateCharts() {
        for (_, chart) in self.charts {
            chart.delegate = nil
        }
    }
    
    func switchChartIntervalType(type: ChandleChartType) {
        for (name, chart) in self.charts {
            if chart.delegate != nil {
                if let newChart = self.switchChartIntervalType(type: type, chartName: name) {
                    self.charts[name] = newChart
                }
            }
        }
    }
    
    fileprivate func switchChartIntervalType(type: ChandleChartType, chartName: String) -> CandleChart? {
        guard let chart = self.getChart(chartName: chartName) else {
            return nil
        }
        
        if type == chart.interval {
            return nil
        }
        
        let delegate = chart.delegate
        chart.delegate = nil
        
        let newChart = CandleChart(chartName: chartName, currencyPair: chart.currencyPair, interval: type, candleCount: chart.candleCount, api: chart.api)
        //newChart.copyTrades(chart: chart)
        newChart.delegate = delegate
        return newChart
    }
    
    func getChart(chartName: String) -> CandleChart? {
        return self.charts[chartName]
    }
    
    func getChartColors(chartName: String) -> ChartColors? {
        return self.chartColors[chartName]
    }
    
    
    static let availableColors = [
        ChartColors(askColor: Color.askQuoteColor, bidColor: Color.bidQuoteColor),
        ChartColors(askColor: UIColor.darkGray, bidColor: UIColor.green)
    ]
    
    var charts: [String:CandleChart]
    var chartColors: [String:ChartColors]
}

