//
//  ViewController.swift
//  ApplePayDemo
//
//  Created by Jack Flintermann on 12/2/14.
//

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
