//
//  CRFTaskInfo.swift
//  CardiorespiratoryFitness
//
//  Copyright © 2018-2021 Sage Bionetworks. All rights reserved.
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

/// A list of all the tasks included in this module.
public enum CRFTaskIdentifier : String, Codable, CaseIterable {
    
    /// Training task for measuring your heart rate.
    case training = "Heart Rate Training"
    
    /// Measure your heart rate while resting.
    case resting = "Resting Heart Rate"
    
    /// Heart snapshot does the stair step VO2 max test with gender and birthYear questions.
    case heartSnapshot = "HeartSnapshot"
    
    func task(with factory: CRFFactory) -> CRFTaskObject {
        do {
            let transformer = CRFTaskTransformer(self)
            let mTask = try factory.decodeTask(with: transformer)
            let task = mTask as! CRFTaskObject
            return task
        }
        catch let err {
            fatalError("Failed to decode the task. \(err)")
        }
    }
}

/// A task info object for the tasks included in this submodule.
public struct CRFTaskInfo : RSDTaskInfo, RSDEmbeddedIconData {

    /// The task identifier for this task.
    public let taskIdentifier: CRFTaskIdentifier
    
    /// The task build for this info.
    public let task: CRFTaskObject
    
    private init(taskIdentifier: CRFTaskIdentifier, task: CRFTaskObject) {
        self.taskIdentifier = taskIdentifier
        self.task = task
    }
    
    /// Default initializer.
    public init(_ taskIdentifier: CRFTaskIdentifier) {
        self.taskIdentifier = taskIdentifier
        
        // Pull the title, subtitle, and detail from the first step in the task resource.
        let factory = (RSDFactory.shared as? CRFFactory) ?? CRFFactory()
        self.task = taskIdentifier.task(with: factory)
        if let step = (task.stepNavigator as? RSDConditionalStepNavigator)?.steps.first as? RSDUIStep {
            self.title = step.title
            self.subtitle = step.subtitle
            self.detail = step.detail
        }
        self.schemaInfo = self.task.schemaInfo
        
        // Set the default image icon.
        switch taskIdentifier {
        case .training, .resting:
            self.icon = try! RSDResourceImageDataObject(imageName: "heartRateIcon", bundle: Bundle(for: CRFFactory.self))
        case .heartSnapshot:
            self.icon = try! RSDResourceImageDataObject(imageName: "heartSnapshotIcon", bundle: Bundle(for: CRFFactory.self))
        }
    }
    
    /// The identifier is the task identifier for this task.
    public var identifier: String {
        return self.task.identifier
    }
    
    /// The title for the task.
    public var title: String?
    
    /// The subtitle for the task.
    public var subtitle: String?
    
    /// The detail for the task.
    public var detail: String?
    
    /// The image icon for the task.
    public var icon: RSDResourceImageDataObject?
    
    /// Estimated minutes to perform the task.
    public var estimatedMinutes: Int {
        switch taskIdentifier {
        case .training:
            return 2
        case .resting:
            return 1
        case .heartSnapshot:
            return 5
        }
    }
    
    /// A schema associated with this task info.
    public var schemaInfo: RSDSchemaInfo?
    
    /// Returns `task`.
    public var resourceTransformer: RSDTaskTransformer? {
        return self.task
    }
    
    public func copy(with identifier: String) -> CRFTaskInfo {
        let task = self.task.copy(with: identifier)
        var copy = CRFTaskInfo(taskIdentifier: taskIdentifier, task: task)
        copy.title = self.title
        copy.subtitle = self.subtitle
        copy.detail = self.detail
        copy.icon = self.icon
        copy.schemaInfo = self.schemaInfo
        return copy
    }
}

/// A task transformer for the resources included in this module.
public struct CRFTaskTransformer : RSDResourceTransformer, Decodable {

    private enum CodingKeys : String, CodingKey {
        case resourceName, packageName
    }
    
    public init(_ taskIdentifier: CRFTaskIdentifier) {
        switch taskIdentifier {
        case .training:
            self.resourceName = "Heartrate_Training"
        case .resting:
            self.resourceName = "Heartrate_Resting"
        case .heartSnapshot:
            self.resourceName = "Heart_Snapshot"
        }
    }
    
    /// Name of the resource for this transformer.
    public let resourceName: String
    
    /// Name of the Android package.
    public var packageName: String?
    
    /// Get the task resource from this bundle.
    public var bundleIdentifier: String? {
        return factoryBundle?.bundleIdentifier
    }
    
    /// The factory bundle points to this framework. (nil-resettable)
    public var factoryBundle: ResourceBundle? {
        get { return _bundle ?? Bundle.module}
        set { _bundle = newValue  }
    }
    private var _bundle: ResourceBundle? = nil
    
    // MARK: Not used.
    
    public var classType: String? {
        return nil
    }
}

/// `RSDTaskGroupObject` is a concrete implementation of the `RSDTaskGroup` protocol.
public struct CRFTaskGroup : RSDTaskGroup, RSDEmbeddedIconData, Decodable {
    
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case identifier, title, detail, icon
    }
    
    /// A short string that uniquely identifies the task group.
    public let identifier: String
    
    /// The primary text to display for the task group in a localized string.
    public let title: String?
    
    /// Additional detail text to display for the task group in a localized string.
    public let detail: String?
    
    /// The optional `RSDResourceImageDataObject` with the pointer to the image.
    public let icon: RSDResourceImageDataObject?
    
    /// The task group object is
    public let tasks: [RSDTaskInfo] = CRFTaskIdentifier.allCases.map { CRFTaskInfo($0) }
}

extension RSDTask {
    
    func findStep(with identifier: String) -> RSDStep? {
        guard let navigator = self.stepNavigator as? RSDConditionalStepNavigator else { return nil }
        for step in navigator.steps {
            if let task = step as? RSDTask, let substep = task.findStep(with: identifier) {
                return substep
            }
            else if step.identifier == identifier {
                return step
            }
        }
        return nil
    }
}

