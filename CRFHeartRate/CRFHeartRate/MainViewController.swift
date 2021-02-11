//
//  MainViewController.swift
//  CRFHeartRate
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

import UIKit
import ResearchUI
import Research
import BridgeApp
import CardiorespiratoryFitness

class MainViewController: UIViewController, RSDTaskViewControllerDelegate {
    
    let archiveManager = SBAArchiveManager()

    /// The page view controller used to control the view controller navigation.
    var pageViewController: UIPageViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the page view controller
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageVC.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.addChild(pageVC)
        pageVC.view.frame = self.view.bounds
        self.view.addSubview(pageVC.view)
        pageVC.view.rsd_alignAllToSuperview(padding: 0)
        pageVC.didMove(toParent: self)
        self.pageViewController = pageVC
        
        loadTask(false)
    }

    func loadTask(_ animated: Bool) {
        do {
            let taskTransformer = RSDResourceTransformerObject(resourceName: "HeartRate_Measurement.json")
            let factory = CRFFactory()
            let task = try factory.decodeTask(with: taskTransformer)
            let vc = RSDTaskViewController(task: task)
            vc.delegate = self
            self.pageViewController.setViewControllers([vc],
                                                       direction: UIPageViewController.NavigationDirection.forward,
                                                       animated: animated,
                                                       completion: nil)
        } catch let err {
            fatalError("Failed to decode the task. \(err)")
        }
    }
    
    func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        loadTask(true)
    }
    
    func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        archiveManager.archiveAndUpload(taskViewModel)
    }
    
    func taskViewController(_ taskViewController: UIViewController, viewControllerForStep stepModel: RSDStepViewModel) -> UIViewController? {
        guard stepModel.step.identifier == "participantID" else { return nil }
        let vc = ParticipantIDStepViewController(step: stepModel.step, parent: stepModel.parent)
        return vc
    }
}

