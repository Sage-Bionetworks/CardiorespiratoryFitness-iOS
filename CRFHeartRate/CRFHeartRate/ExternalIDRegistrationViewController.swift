//
//  ExternalIDRegistrationViewController.swift
//  mPower2
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import ResearchUI
import Research
import BridgeSDK
import BridgeApp

class ExternalIDRegistrationStep : RSDUIStepObject, RSDFormUIStep, RSDStepViewControllerVendor {
    
    open func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return ExternalIDRegistrationViewController(step: self, parent: parent)
    }
    
    let inputFields: [RSDInputField] = {
        let prompt = NSLocalizedString("external ID", comment: "Localized string for the external ID prompt")
        let inputField = RSDInputFieldObject(identifier: "externalId", dataType: .base(.string), uiHint: .textfield, prompt: prompt)
        inputField.isOptional = false
        return [inputField]
    }()
    
    required init(identifier: String, type: RSDStepType?) {
        super.init(identifier: identifier, type: type)
        commonInit()
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        commonInit()
    }
    
    private func commonInit() {
        if self.text == nil && self.title == nil {
            self.text = NSLocalizedString("Enter your external ID to get started.", comment: "Default text for an external ID registration step.")
        }
    }
}

class ExternalIDRegistrationViewController: RSDTableStepViewController {
    
    func signUpAndSignIn(completion: @escaping SBBNetworkManagerCompletionBlock) {
        let externalIdResultIdentifier = "externalId"
        guard let externalId = self.stepViewModel.taskResult.findAnswerResult(with: externalIdResultIdentifier)?.value as? String
            else {
                return
        }
            
        // Sign in using legacy style so the Android code doesn't have to change. syoung 11/02/2018
        BridgeSDK.authManager.signIn(withExternalId: externalId, password: externalId, completion: { (task, result, error) in
            completion(task, result, error)
        })
    }
    
    override func goForward() {
        guard validateAndSave()
            else {
                return
        }
        
        self.nextButton?.isEnabled = false
        self.signUpAndSignIn { (task, result, error) in
            DispatchQueue.main.async {
                if error == nil || (error! as NSError).code == SBBErrorCode.serverPreconditionNotMet.rawValue {
                   super.goForward()
                } else {
                    self.nextButton?.isEnabled = true
                    self.presentAlertWithOk(title: "Error attempting sign in", message: error!.localizedDescription, actionHandler: nil)
                    // TODO: emm 2018-04-25 handle error from Bridge
                    // 400 is the response for an invalid external ID
                    debugPrint("Error attempting to sign up and sign in:\n\(String(describing: error))\n\nResult:\n\(String(describing: result))")
                }
            }
        }
    }

}
