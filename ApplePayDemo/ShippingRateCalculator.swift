//
//  ShippingRateCalculator.swift
//  ApplePayDemo
//
//  Created by Jack Flintermann on 12/2/14.
//

import UIKit
import PassKit

class ShippingRateCalculator: NSObject {
    
    class func defaultShippingMethod() -> PKShippingMethod {
        let shippingMethod = PKShippingMethod(label: "Shipping (Cost TBD)", amount: NSDecimalNumber(string: "0"))
        shippingMethod.identifier = ""
        shippingMethod.detail = ""
        return shippingMethod
    }
    
class func fetchShippingRatesForAddress(address: ABRecord!, completion: (([PKShippingMethod]?, NSError?) -> Void)) {
    
    func urlForAddress(address: ABRecord!) -> NSURL {
        let base = "https://applepay-shipping-example.herokuapp.com/rates"
        let addressValues : CFTypeRef = ABRecordCopyValue(address, kABPersonAddressProperty).takeRetainedValue();
        if ABMultiValueGetCount(addressValues) > 0 {
            var dict = ABMultiValueCopyValueAtIndex(addressValues, 0).takeRetainedValue() as NSDictionary
            var urlArgs = [String]()
            let keyMapping = [
                String(kABPersonAddressStreetKey): "address",
                String(kABPersonAddressCityKey) : "city",
                String(kABPersonAddressStateKey) : "state",
                String(kABPersonAddressZIPKey) : "zip",
                String(kABPersonAddressCountryKey) : "country",
            ]
            for (key : String, value : String) in keyMapping {
                if let queryParam = dict[key] as String? {
                    if let escapedQueryParam = queryParam.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
                        urlArgs.append("\(value)=\(escapedQueryParam)")
                    }
                }
            }
            let urlString = base + "?" + join("&", urlArgs)
            return NSURL(string: urlString) ?? NSURL(string: base)!
        }
        return NSURL(string: base)!
    }
    
    let url = urlForAddress(address)
    NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
        if (error != nil) {
            completion(nil, error)
            return
        }
        if data != nil {
            if let rawRates = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [Dictionary<String, String>] {
                let shippingMethods = map(rawRates, { (rate : [String : String]) -> PKShippingMethod in
                    let label = rate["carrier"]! + " " + rate["service"]!
                    let amount = NSDecimalNumber(string: rate["amount"])
                    let shippingMethod = PKShippingMethod(label: label, amount: amount)
                    shippingMethod.identifier = rate["id"]
                    shippingMethod.detail = rate["formatted_arrival_date"] ?? "" // make sure to set this, or it will display as (NULL) in the UI.
                    return shippingMethod
                })
                completion(shippingMethods, nil)
                return
            }
        }
    }).resume()
}
}
