//
//  ParticipantIDStepViewController.swift
//  CRFHeartRate
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

class ParticipantIDStepViewController: RSDTableStepViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func goForward() {
        guard validateAndSave() else { return }
        guard let collectionResult = self.stepViewModel.findStepResult() as? RSDCollectionResult,
            let answerResult = collectionResult.inputResults.first as? RSDAnswerResult,
            let participantID = answerResult.value as? String
            else {
                fatalError("Attempting to go forward without an answer result.")
        }
        guard !UserDefaults.standard.bool(forKey: participantID)
            else {
                handlePreviouslyUsed(participantID)
                return
        }
        
        UserDefaults.standard.set(true, forKey: participantID)
        super.goForward()
    }
    
    func handlePreviouslyUsed(_ participantID: String) {
        self.presentAlertWithOk(title: nil, message: "ID \(participantID) has already been used on this phone.") { (_) in
            self.clearAnswers()
        }
    }
    
    func clearAnswers() {
        do {
            let indexPath = IndexPath(item: 0, section: 0)
            try self.tableData!.saveAnswer(NSNull(), at: indexPath)
            self.refreshAnswer(at: indexPath)
        }
        catch let err {
            debugPrint("Failed to save null answer: \(err)")
        }
    }
}
