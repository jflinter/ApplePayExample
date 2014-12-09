//
//  ShippingRateCalculator.swift
//  ApplePayDemo
//
//  Created by Jack Flintermann on 12/2/14.
//

import UIKit
import PassKit
import AddressBook
import Alamofire

func addressesForRecord(record: ABRecord) -> [[String: String]] {
    var addresses: [[String: String]] = []
    let values: ABMultiValue = ABRecordCopyValue(record, kABPersonAddressProperty).takeRetainedValue()
    for index in 0..<ABMultiValueGetCount(values) {
        if let address = ABMultiValueCopyValueAtIndex(values, index).takeRetainedValue() as? [String: String] {
            addresses.append(address)
        }
    }

    return addresses
}

func fetchShippingMethodsForAddress(address: [String: String], completion: ([PKShippingMethod]?) -> Void) {
    let parameters = [
        "street": address[kABPersonAddressStreetKey] ?? "",
        "city": address[kABPersonAddressCityKey] ?? "",
        "state": address[kABPersonAddressStateKey] ?? "",
        "zip": address[kABPersonAddressZIPKey] ?? "",
        "country": address[kABPersonAddressCountryKey] ?? ""
    ]

    Alamofire.request(.GET, "https://applepay-shipping-example.herokuapp.com/rates", parameters: parameters)
        .responseJSON { (_, _, JSON, _) in
            if let rates = JSON as? [[String: String]] {
                let shippingMethods = map(rates) { (rate) -> PKShippingMethod in
                    let identifier = rate["id"]
                    let carrier = rate["carrier"] ?? "Unknown Carrier"
                    let service = rate["service"] ?? "Unknown Service"
                    let amount = NSDecimalNumber(string: rate["amount"])
                    let arrival = rate["formatted_arrival_date"] ?? "Unknown Arrival"

                    let shippingMethod = PKShippingMethod(label: "\(carrier) \(service)", amount: amount)
                    shippingMethod.identifier = identifier
                    shippingMethod.detail = arrival

                    return shippingMethod
                }
            }
    }
}
