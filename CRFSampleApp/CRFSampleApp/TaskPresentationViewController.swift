//
//  TaskPresentationViewController.swift
//  RSDCatalog
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
import JsonModel
import Research
import CardiorespiratoryFitness

/// The data storage in this case is an example only. As such, the data will not be
/// shared to user defaults but only in local memory.
var sex: CRFGender?
var birthYear: Int?

class TaskPresentationViewController: UITableViewController, RSDTaskViewControllerDelegate {
    
    var taskInfo: CRFTaskInfo!
    var result: ResultData?
    var firstAppearance: Bool = true
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if firstAppearance, (self.result == nil), let taskInfo = self.taskInfo {
            let task = taskInfo.task
            task.gender = sex
            task.birthYear = birthYear
            let taskViewModel = RSDTaskViewModel(task: task)
            let taskViewController = RSDTaskViewController(taskViewModel: taskViewModel)
            taskViewController.delegate = self
            self.present(taskViewController, animated: true, completion: nil)
        }
        firstAppearance = false
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ResultTableViewController, let result = self.result {
            vc.result = result
            vc.title = vc.result!.identifier
            vc.navigationItem.title = vc.title
        }
    }
    
    // MARK: - RSDTaskControllerDelegate
    
    func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        
        // populate the results
        self.result = taskController.taskViewModel.taskResult
        self.tableView.reloadData()
        
        // dismiss the view controller
        (taskController as? UIViewController)?.dismiss(animated: true) {
        }
        
        var debugResult: String = self.result!.identifier
        debugResult.append("\n\n=== Completed: \(reason) error:\(String(describing: error))")
        print(debugResult)
    }
    
    func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        
        // This method is only called on a successful completion of the task when there is data to be
        // saved. This method will *not* be called if the participant cancels the task or it errors out.
        print("\n\n=== Ready to Save: \(taskViewModel.description)")
        
        // Look to see if the sex/birthYear should be updated
        if let answerResult = taskViewModel.taskResult.findAnswerResult(with: CRFDemographicsKeys.gender.stringValue),
            let value = answerResult.value as? String,
            let result = CRFGender(rawValue: value) {
            sex = result
        }
        
        if let answerResult = taskViewModel.taskResult.findAnswerResult(with: CRFDemographicsKeys.birthYear.stringValue),
            let value = answerResult.value as? Int {
            birthYear = value
        }
    }
    
    func taskViewController(_ taskViewController: UIViewController, shouldShowTaskInfoFor step: Any) -> Bool {
        // TODO: syoung 01/18/2019 clean up JSON and Factory stuff for showing the intro step.
        return false
    }
}
