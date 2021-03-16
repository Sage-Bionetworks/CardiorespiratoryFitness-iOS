//
//  CRFTaskObject.swift
//  CardiorespiratoryFitness
//
//  Copyright © 2019-2021 Sage Bionetworks. All rights reserved.
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

import Foundation
import JsonModel
import ResearchUI
import Research

extension RSDIdentifier {
    static let demographics: RSDIdentifier = "demographics"
}

/// Options for the value of the demographics question about gender.
public enum CRFGender : String, Codable {
    case male, female, other
}

public enum CRFDemographicsKeys : String, CodingKey, Codable {
    case birthYear, gender
}

extension RSDTaskType {
    static let crf: RSDTaskType = "crf"
}

public final class CRFTaskObject: AssessmentTaskObject, RSDTaskDesign {
    public override class func defaultType() -> RSDTaskType {
        .crf
    }
    
    /// The camera settings to use for the heart rate steps (nil resettable).
    public var cameraSettings : CRFCameraSettings? {
        get { return heartRateSteps().first?.cameraSettings ?? nil }
        set {
            for step in heartRateSteps() {
                step.cameraSettings = newValue ?? CRFCameraSettings()
            }
        }
    }

    private func heartRateSteps() -> [CRFHeartRateStep] {
        guard let navigator = self.stepNavigator as? RSDConditionalStepNavigator else { return [] }
        let steps = navigator.steps.compactMap { (step) -> CRFHeartRateStep? in
            if let hrStep = step as? CRFHeartRateStep {
                return hrStep
            }
            guard let sectionStep = step as? RSDSectionStep else { return nil }
            return sectionStep.steps.first(where: { $0 is CRFHeartRateStep }) as? CRFHeartRateStep
        }
        return steps
    }

    /// The birth year of the participant who is doing this task.
    public var birthYear: Int? {
        get {
            return previousRunData[CRFDemographicsKeys.birthYear.stringValue] as? Int
        }
        set {
            previousRunData[CRFDemographicsKeys.birthYear.stringValue] = newValue
        }
    }
    
    /// The gender of the participant who doing this task.
    public var gender: CRFGender? {
        get {
            guard let value = previousRunData[CRFDemographicsKeys.gender.stringValue] as? String
                else {
                    return nil
            }
            return CRFGender(rawValue: value)
        }
        set {
            previousRunData[CRFDemographicsKeys.gender.stringValue] = newValue?.stringValue
        }
    }
    
    private var previousRunData: [String : JsonSerializable] = [:]

    /// Override task setup to get the demographics data from a previous run.
    public override func setupTask(with data: RSDTaskData?, for path: RSDTaskPathComponent) {
        previousRunData = (data?.json as? [String : JsonSerializable]) ?? [:]
        super.setupTask(with: data, for: path)
    }
    
    func hasDemographics() -> Bool {
        return self.birthYear != nil
    }
    
    /// Override to check if this is one of the demographics questions.
    public override func shouldSkipStep(_ step: RSDStep) -> (shouldSkip: Bool, stepResult: ResultData?) {
        guard hasDemographics() else { return (false, nil) }
        if let questionStep = step as? QuestionStep {
            let answerResult = questionStep.instantiateAnswerResult()
            if let value = previousRunData[step.identifier] as? JsonValue {
                answerResult.jsonValue = JsonElement(value)
            }
            return (true, answerResult)
        }
        else if step.identifier == RSDIdentifier.demographics {
            let result = step.instantiateStepResult()
            return (true, result)
        }
        else {
            return (false, nil)
        }
    }
    
    /// Return the design system from the factory.
    public var designSystem: RSDDesignSystem {
        return CRFFactory.designSystem
    }
}
