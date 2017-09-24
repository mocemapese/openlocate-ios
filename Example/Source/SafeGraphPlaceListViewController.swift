//
//  SafeGraphPlaceListViewController.swift
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

class SafeGraphPlaceListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel!

    var places = [SafeGraphPlace]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "tab_logo"))
    }

    @IBAction func refreshButtonClicked() {
        fetchCurrentPlaces()
    }

    private func fetchCurrentPlaces() {
        activity.startAnimating()
        infoLabel.isHidden = true

        do {
            try OpenLocate.shared.fetchCurrentLocation { location, _ in
                if let location = location {
                    fetchSafeGraphPlaces(location: location)
                    return
                }

                activity.stopAnimating()
                resetPlaces()
                showError(message: "Could not fetch location. Please try again.")
            }
        } catch _ {
            activity.stopAnimating()
            resetPlaces()
            showError(message: "Could not fetch location. Please try again.")
        }
    }

    private func fetchSafeGraphPlaces(location: OpenLocateLocation) {
        SafeGraphStore.shared.fetchNearbyPlaces(location: location) { places, _ in
            self.activity.stopAnimating()

            if let places = places {
                self.places = places
                self.tableView.reloadData()
                return
            }

            self.resetPlaces()
            self.showError(message: "SafeGraph place could not be fetched. Please try again")
        }
    }

    private func resetPlaces() {
        self.infoLabel.isHidden = false
        places = [SafeGraphPlace]()
        tableView.reloadData()
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)

        let okay = UIAlertAction(title: "OK", style: .destructive) { _ in
            alert.dismiss(animated: false, completion: nil)
        }
        alert.addAction(okay)

        present(alert, animated: true, completion: nil)
    }
}

extension SafeGraphPlaceListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceTableViewCell") as? SafeGraphPlaceTableViewCell

        cell!.update(place: places[indexPath.row])
        return cell!
    }
}
