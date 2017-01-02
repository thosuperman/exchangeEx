//
//  Account+CoreDataProperties.swift
//  
//
//  Created by 渡部郷太 on 1/2/17.
//
//

import Foundation
import CoreData


extension Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account");
    }

    @NSManaged public var userId: String
    @NSManaged public var password: String
    @NSManaged public var lastLoginDate: NSNumber?
    @NSManaged public var lastBackgroundDate: NSNumber?
    @NSManaged public var activeExchangeName: String
    @NSManaged public var salt: String
    @NSManaged public var exchanges: NSSet

}

// MARK: Generated accessors for exchanges
extension Account {

    @objc(addExchangesObject:)
    @NSManaged public func addToExchanges(_ value: ExchangeAccount)

    @objc(removeExchangesObject:)
    @NSManaged public func removeFromExchanges(_ value: ExchangeAccount)

    @objc(addExchanges:)
    @NSManaged public func addToExchanges(_ values: NSSet)

    @objc(removeExchanges:)
    @NSManaged public func removeFromExchanges(_ values: NSSet)

}
