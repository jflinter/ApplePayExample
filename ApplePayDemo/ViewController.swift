//
//  ViewController.swift
//  ApplePayDemo
//
//  Created by Jack Flintermann on 12/2/14.
//

import UIKit
import PassKit

class ViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {

    override func viewDidAppear(animated: Bool) {
        if PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks([PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]) {
            let request = PKPaymentRequest()
            request.supportedNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]
            request.countryCode = "US"
            request.currencyCode = "USD"
            request.merchantIdentifier = "<#Replace me with your Apple Merchant ID#>"
            request.merchantCapabilities = PKMerchantCapability.Capability3DS
            request.paymentSummaryItems = self.paymentSummaryItems(nil)
            request.requiredShippingAddressFields = PKAddressField.PostalAddress
            let vc = PKPaymentAuthorizationViewController(paymentRequest: request)
            vc.delegate = self
            presentViewController(vc, animated: true, completion: nil)
        }
        else {
            // You'll have to collect your user's payment details another way, such as building your own form.
        }
    }
    
    // MARK: PKPaymentAuthorizationViewControllerDelegate
        
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didAuthorizePayment payment: PKPayment!, completion: ((PKPaymentAuthorizationStatus) -> Void)!) {
        self.processPayment(payment, completion: completion)
    }

    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController!) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func processPayment(payment: PKPayment, completion: (PKPaymentAuthorizationStatus -> Void)) {
        // Use your payment processor's SDK to finish charging your user.
        // When this is done, call completion(PKPaymentAuthorizationStatus.Success)
        completion(PKPaymentAuthorizationStatus.Failure)
    }

    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingAddress address: ABRecord!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]!, [AnyObject]!) -> Void)!) {
        
        ShippingRateCalculator.fetchShippingRatesForAddress(address, completion: { (shippingMethods, error) -> Void in
            if (error != nil || shippingMethods == nil || shippingMethods!.isEmpty) {
                completion(PKPaymentAuthorizationStatus.InvalidShippingPostalAddress, nil, nil)
                return
            }
            completion(PKPaymentAuthorizationStatus.Success, shippingMethods, self.paymentSummaryItems(shippingMethods![0]))
        })
    }

    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didSelectShippingMethod shippingMethod: PKShippingMethod!, completion: ((PKPaymentAuthorizationStatus, [AnyObject]!) -> Void)!) {
        completion(PKPaymentAuthorizationStatus.Success, paymentSummaryItems(shippingMethod))
    }

    func paymentSummaryItems(method: PKShippingMethod?) -> ([PKPaymentSummaryItem]) {
        
        let wax = PKPaymentSummaryItem(label: "Mustache Wax", amount: NSDecimalNumber(string: "10.00"))
        let shipping = method ?? ShippingRateCalculator.defaultShippingMethod()
        let discount = PKPaymentSummaryItem(label: "Movember discount", amount: NSDecimalNumber(string: "-1.00"))
        let totalAmount = wax.amount.decimalNumberByAdding(shipping.amount).decimalNumberByAdding(discount.amount)
        let total = PKPaymentSummaryItem(label: "NSHipster", amount: totalAmount)
        
        return [wax, shipping, discount, total]
    }
}
