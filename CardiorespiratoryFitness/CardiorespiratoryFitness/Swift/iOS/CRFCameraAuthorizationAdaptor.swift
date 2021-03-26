//
//  CRFCameraAuthorizationAdaptor.swift
//  CardiorespiratoryFitness
//
//  Created by Shannon Young on 5/16/19.
//  Copyright © 2019-2021 Sage Bionetworks. All rights reserved.
//
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
import AVFoundation
import Research
import MobilePassiveData

/// `CRFCameraAuthorizationAdaptor` is a wrapper for the AVFoundation library that allows a general-purpose
/// step or task to query this library for authorization if and only if that library is required by the
/// application.
///
/// Before using this adaptor with a permission step, the calling application or framework will need to
/// register the adaptor using `PermissionAuthorizationHandler.registerAdaptorIfNeeded()`.
///
/// - seealso: `PermissionsStepViewController`
public class CRFAVAuthorization : PermissionAuthorizationAdaptor {
    
    public static let shared = CRFAVAuthorization()
    
    /// This adaptor is intended for checking for motion sensor permissions.
    public var permissions: [PermissionType] = [StandardPermissionType.camera,
                                                   StandardPermissionType.microphone]
    
    private func _mediaType(for permission: String) -> AVMediaType? {
        guard let permissionType = StandardPermissionType(rawValue: permission)
            else {
                return nil
        }
        switch permissionType {
        case .camera:
            return .video
        case .microphone:
            return .audio
        default:
            return nil
        }
    }
    
    /// Returns authorization status for `.camera` and `.microphone` permissions.
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        guard let mediaType = _mediaType(for: permission)
            else {
                assertionFailure("This is not a recognized audiovisual permission.")
                return .notDetermined
        }
        
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        @unknown default:
            assertionFailure("This is not a recognized audiovisual permission.")
            return .denied
        }
    }
    
    /// Request authorization to access either video or audio.
    public func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        guard let mediaType = _mediaType(for: permission.identifier)
            else {
                assertionFailure("This is not a recognized audiovisual permission.")
                let error = PermissionError.notAuthorized(permission, .denied)
                completion(.denied, error)
                return
        }
        
        AVCaptureDevice.requestAccess(for: mediaType) { (granted) in
            if granted {
                completion(.authorized, nil)
            } else {
                let error = PermissionError.notAuthorized(permission, .denied)
                completion(.denied, error)
            }
        }
    }
}
