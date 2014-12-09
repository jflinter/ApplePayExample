// ShippingRates.swift
//
// Copyright (c) 2014 NSHipster (http://nshipster.com/)
//
// Created by Jack Flintermann
// http://nshipster.com/apple-pay/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
