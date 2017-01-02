//
//  PositionCreateViewController.swift
//  zai
//
//  Created by 渡部郷太 on 12/30/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation
import UIKit


class PositionEditor : NSObject {
    init(title: String, message: String) {
        self.controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    
    let controller: UIAlertController
    var priceTextField: UITextField?
    var amountextField: UITextField?
}


class ValidatablePositionEditor : PositionEditor, UITextFieldDelegate {
    override init(title: String, message: String) {
        super.init(title: title, message: message)
    }
    
    // UITextFieldDelegate
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if !self.allowInput(existingInput: textField.text!, addedString: string) {
            return false
        }
        
        // all field are filled by valid value? if no, disable ok button.
        self.controller.actions.last?.isEnabled = true
        
        let nsstring = textField.text! as NSString
        let newInput = nsstring.replacingCharacters(in: range, with: string)
        var newValue = 0.0
        if let value = Double(newInput as String) {
            newValue = value
        }
        if newValue <= 0.0 {
            self.controller.actions.last?.isEnabled = false
        }
        
        let textFields = self.controller.textFields
        for field in textFields! {
            if textField.tag != field.tag {
                if field.text?.characters.count == 0 {
                    self.controller.actions.last?.isEnabled = false
                }
                if let value = Double(field.text!) {
                    if value <= 0.0 {
                        self.controller.actions.last?.isEnabled = false
                    }
                }
            }
        }
        return true
    }
    
    func allowInput(existingInput: String, addedString: String) -> Bool {
        if addedString.isEmpty {
            return true
        } else {
            if self.validateExistingInput(string: existingInput) &&
               self.validateInput(string: addedString) &&
               self.validateCombinationInput(existingInput: existingInput, addedString: addedString) {
                return true
            }
        }
        return false
    }
    
    func validateExistingInput(string: String) -> Bool {
        var pattern = "^[0-9]+\\."
        var reg = try! NSRegularExpression(pattern: pattern)
        var matches = reg.matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
        if matches.count == 0 {
            return true
        }
        
        // for amount
        pattern = "^[0-9]+\\.[0-9]{4}$"
        reg = try! NSRegularExpression(pattern: pattern)
        matches = reg.matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
        return matches.count == 0
    }
    
    func validateInput(string: String) -> Bool {
        return Double(string) != nil || string == "."
    }
    
    func validateCombinationInput(existingInput: String, addedString: String) -> Bool {
        if addedString == "." && existingInput.contains(".") {
            return false
        }
        return true
    }
}

protocol PositionCreateDelegate {
    func createOk(position: Position)
    func createCancel()
}

class PositionCreateViewController : ValidatablePositionEditor {
    
    init(trader: Trader) {
        self.trader = trader
        super.init(title: "ポシション追加", message: "新しいロングポジションを追加します。注文は執行されません。")
        
        self.addPriceField()
        self.addAmountField()
        self.addCancelAction()
        self.addOkAction()
    }
    
    fileprivate func addPriceField() {
        self.controller.addTextField { (textField) -> Void in
            self.priceTextField = textField
            textField.tag = 0
            textField.placeholder = "価格"
            textField.keyboardType = .numberPad
            textField.delegate = self
        }
    }
    
    fileprivate func addAmountField() {
        self.controller.addTextField { (textField) -> Void in
            self.amountextField = textField
            textField.tag = 1
            textField.placeholder = "数量"
            textField.keyboardType = .decimalPad
            textField.delegate = self
        }
    }
    
    fileprivate func addCancelAction() {
        let action = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            self.delegate?.createCancel()
        }
        self.controller.addAction(action)
    }
    
    fileprivate func addOkAction() {
        let action = UIAlertAction(title: "追加", style: .default, handler: { action in
            let position = PositionRepository.getInstance().createLongPosition(trader: self.trader)
            let log = TradeLogRepository.getInstance().create(userId: self.trader.account.userId, action: .OPEN_LONG_POSITION, traderName: self.trader.name, orderAction: "bid", orderId: nil, currencyPair: "btc_jpy", price: Double(self.priceTextField!.text!)!, amount: Double(self.amountextField!.text!)!, positionId: position.id)
            position.addLog(log)
            position.open()
            self.delegate?.createOk(position: position)
        })
        action.isEnabled = false
        self.controller.addAction(action)
    }
    
    let trader: Trader
    var delegate: PositionCreateDelegate?
}


protocol PositionEditDelegate {
    func editOk(position: Position)
    func editCancel()
}

class PositionEditViewController : ValidatablePositionEditor {
    
    init(trader: Trader, position: Position) {
        self.trader = trader
        self.position = position
        super.init(title: "ポシション編集", message: "")
        
        self.addPriceField()
        self.addAmountField()
        self.addCancelAction()
        self.addOkAction()
    }
    
    fileprivate func addPriceField() {
        self.controller.addTextField { (textField) -> Void in
            self.priceTextField = textField
            textField.tag = 0
            textField.placeholder = "価格"
            textField.text? = Int(self.position.price).description
            textField.keyboardType = .numberPad
            textField.delegate = self
        }
    }
    
    fileprivate func addAmountField() {
        self.controller.addTextField { (textField) -> Void in
            self.amountextField = textField
            textField.tag = 1
            textField.placeholder = "数量"
            textField.text? = self.position.amount.description
            textField.keyboardType = .decimalPad
            textField.delegate = self
        }
    }
    
    fileprivate func addCancelAction() {
        let action = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            self.delegate?.editCancel()
        }
        self.controller.addAction(action)
    }
    
    fileprivate func addOkAction() {
        let action = UIAlertAction(title: "保存", style: .default, handler: { action in
            self.position.price = Double(self.priceTextField!.text!)!
            self.position.amount = Double(self.amountextField!.text!)!
            self.delegate?.editOk(position: self.position)
        })
        action.isEnabled = false
        self.controller.addAction(action)
    }
    
    let trader: Trader
    let position: Position
    var delegate: PositionEditDelegate?
}
