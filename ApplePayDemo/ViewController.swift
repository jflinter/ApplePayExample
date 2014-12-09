// ViewController.swift
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

class ViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {
    var defaultShippingMethod: PKShippingMethod {
        let shippingMethod = PKShippingMethod(label: "Shipping (Cost TBD)", amount: NSDecimalNumber(double: 0))
        shippingMethod.identifier = ""
        shippingMethod.detail = ""

        return shippingMethod
    }

    func paymentSummaryItemsForShippingMethod(shipping: PKShippingMethod) -> ([PKPaymentSummaryItem]) {
        let wax = PKPaymentSummaryItem(label: "Mustache Wax", amount: NSDecimalNumber(string: "10.00"))
        let discount = PKPaymentSummaryItem(label: "Discount", amount: NSDecimalNumber(string: "-1.00"))

        let totalAmount = wax.amount.decimalNumberByAdding(discount.amount)
            .decimalNumberByAdding(shipping.amount)
        let total = PKPaymentSummaryItem(label: "NSHipster", amount: totalAmount)

        return [wax, discount, shipping, total]
    }

    // MARK: - UIViewController

    override func viewDidAppear(animated: Bool) {
        let supportedNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]

        if PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(supportedNetworks) {
            let request = PKPaymentRequest()
            request.supportedNetworks = supportedNetworks
            request.countryCode = "US"
            request.currencyCode = "USD"
            request.merchantIdentifier = "<#Replace me with your Apple Merchant ID#>"
            request.merchantCapabilities = PKMerchantCapability.Capability3DS
            request.paymentSummaryItems = self.paymentSummaryItemsForShippingMethod(defaultShippingMethod)
            request.requiredShippingAddressFields = PKAddressField.PostalAddress

            let viewController = PKPaymentAuthorizationViewController(paymentRequest: request)
            viewController.delegate = self
            presentViewController(viewController, animated: true, completion: nil)
        } else {
            // You'll have to collect your user's payment details another way, such as building your own form.
        }
    }
    
    // MARK: - PKPaymentAuthorizationViewControllerDelegate
        
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didAuthorizePayment payment: PKPayment!, completion: ((PKPaymentAuthorizationStatus) -> Void)!) {
        // Use your payment processor's SDK to finish charging your user.
        // When this is done, call completion(PKPaymentAuthorizationStatus.Success)
    }

    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController!) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingMethod shippingMethod: PKShippingMethod!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]!) -> Void)!) {
        completion(PKPaymentAuthorizationStatus.Success, paymentSummaryItemsForShippingMethod(shippingMethod))
    }

    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingAddress record: ABRecord!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]!, [AnyObject]!) -> Void)!) {
        if let address = addressesForRecord(record).first {
            fetchShippingMethodsForAddress(address) { (shippingMethods) in
                switch shippingMethods?.count {
                case .None:
                    completion(PKPaymentAuthorizationStatus.Failure, nil, nil)
                case .Some(0):
                    completion(PKPaymentAuthorizationStatus.InvalidShippingPostalAddress, nil, nil)
                default:
                    completion(PKPaymentAuthorizationStatus.Success, shippingMethods, self.paymentSummaryItemsForShippingMethod(shippingMethods!.first!))
                }
            }
        } else {
            completion(PKPaymentAuthorizationStatus.Failure, nil, nil)
        }
    }
}
