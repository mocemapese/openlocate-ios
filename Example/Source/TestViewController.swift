//
//  TestViewController.swift
//
//  Copyright (c) 2017 OpenLocate
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import OpenLocate

class TestViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    @IBAction func startTracking(_ sender: Any) {

        do {
            let uuid = UUID(uuidString: (Bundle.main.object(forInfoDictionaryKey: "ProviderId") as? String)!)
            let configuration = SafeGraphConfiguration(
                uuid: uuid!,
                token: (Bundle.main.object(forInfoDictionaryKey: "Token") as? String)!
            )
            try OpenLocate.shared.startTracking(with: configuration)
            onStartTracking()
        } catch OpenLocateError.invalidConfiguration(let message) {
            showError(message: message)
        } catch OpenLocateError.locationDisabled(let message) {
            showError(message: message)
        } catch OpenLocateError.locationUnAuthorized(let message) {
            showError(message: message)
        } catch OpenLocateError.locationServiceConflict(let message) {
            showError(message: message)
        } catch OpenLocateError.locationMissingAuthorizationKeys(let message) {
            showError(message: message)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    @IBAction func stopTracking(_ sender: Any) {
        OpenLocate.shared.stopTracking()
        onStopTracking()
    }

    private func onStartTracking() {
        startButton.isEnabled = false
        stopButton.isEnabled = true
    }

    private func onStopTracking() {
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }

    private func showError(message: String) {
        let alert = UIAlertController(
            title: "error",
            message: message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(title: "OK", style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)

        present(alert, animated: true, completion: nil)
    }
}
