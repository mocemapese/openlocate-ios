//
//  SettingsViewController.swift
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

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerContainer: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    var selectedIndex = 0

    private var intervals = Array(1...100)
    private var accuracies = ["high", "medium", "low"]

}

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell") as? SettingsTableViewCell

        switch indexPath.row {
        case 0:
            cell?.title.text = "Location Interval"
            cell?.value.text = "\(Settings.shared.locationInterval) minutes"
        case 1:
            cell?.title.text = "Location Accuracy"
            cell?.value.text = "\(Settings.shared.accuracy.rawValue.uppercased())"
        case 2:
            cell?.title.text = "Transmission Interval"
            cell?.value.text = "\(Settings.shared.transmissionInterval) minutes"
        default:
            cell?.title.text = "Location Interval"
            cell?.value.text = "\(Settings.shared.transmissionInterval) minutes"
        }

        return cell!
    }

}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        showPickerContainer()
        pickerView.reloadComponent(0)
        setSelectedRow()
    }
}

extension SettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if selectedIndex == 1 {
            return 3
        }

        return intervals.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if selectedIndex == 1 {
            return accuracies[row].uppercased()
        }

        return "\(intervals[row]) minutes"
    }

    @IBAction func doneButtonClicked() {
        switch selectedIndex {
        case 0:
            Settings.shared.locationInterval = intervals[pickerView.selectedRow(inComponent: 0)]
        case 2:
            Settings.shared.transmissionInterval = intervals[pickerView.selectedRow(inComponent: 0)]
        default:
            let accuracy = accuracies[pickerView.selectedRow(inComponent: 0)]
            Settings.shared.accuracy = LocationAccuracy(rawValue: accuracy)!
        }
        hidePickerContainer()
        tableView.reloadData()
    }

    private func setSelectedRow() {
        switch selectedIndex {
        case 0:
            pickerView.selectRow(
                intervals.index(of: Settings.shared.locationInterval)!,
                inComponent: 0,
                animated: false
                )
        case 2:
            pickerView.selectRow(
                intervals.index(of: Settings.shared.transmissionInterval)!,
                inComponent: 0,
                animated: false
            )
        default:
            pickerView.selectRow(
                accuracies.index(of: Settings.shared.accuracy.rawValue)!,
                inComponent: 0,
                animated: false
            )
        }
    }

    private func showPickerContainer() {
        self.bottomConstraint.constant = 44
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func hidePickerContainer() {
        self.bottomConstraint.constant = -250
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
