//
//  ViewController.swift
//  GoPlatforms
//
//  Created by Kevin Stewart on 2017-05-18.
//  Copyright © 2017 Kevin Stewart. All rights reserved.
//

import UIKit
import Kanna
import Alamofire

class ViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate {
    
    var dataSource = [GoService]()
    var filteredDataSource = [GoService]()
    
    let searchController = UISearchController(searchResultsController: nil)
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var userIsSearching: Bool {
        return searchController.isActive && searchController.searchBar.text != ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupActivityIndicator()
        
        tableView.register(UINib(nibName: "GoServiceCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        activityIndicator.startAnimating()
        scrapeUnionPlatform()
    }
    
    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
    }
    
    // MARK: - UITableViewController -
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! GoServiceCell
        let service = userIsSearching ? filteredDataSource[indexPath.row] : dataSource[indexPath.row]
        cell.configure(service: service)
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userIsSearching {
            return filteredDataSource.count
        }
        return dataSource.count
    }
    
    // MARK: - UISearchController -
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filterContent(searchText: searchText)
    }
    
    func filterContent(searchText: String, scope: String = "All") {
        filteredDataSource = dataSource.filter({ $0.route.lowercased().contains(searchText.lowercased()) })
        tableView.reloadData()
    }
    
    // MARK: - UIRefreshControl -
    @IBAction func didRefresh(_ sender: UIRefreshControl) {
        scrapeUnionPlatform()
    }
    
    // MARK: - Move this out of here later -
    func scrapeUnionPlatform() {
        request("http://www.gotransit.com/publicroot/en/mobile/").responseString { response in
            guard let html = response.result.value else { assertionFailure("Failed to get response"); return }
            self.parse(html: html)
        }
    }
    
    func parse(html: String) {
        guard let doc = HTML(html: html, encoding: String.Encoding.utf8) else {
            assertionFailure("Failed to parse UTF8")
            return
        }
        
        defer {
            tableView.reloadData()
            refreshControl?.endRefreshing()
            activityIndicator.stopAnimating()
        }
        
        for row in doc.css("tr") {
            if let text = row.text {
                if text.contains("GO Service") { continue }
            }
            var time: Date?
            var route: String?
            var type: GoService.VehicleType?
            var platform: Int?
            for (index, element) in row.css("td").enumerated() {
                guard let element = element.text else { continue }
                let text = String(htmlEncodedString: element).trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch index {
                case 0:
                    guard let parsedTime = DateFormatter.timeFormatter.date(from: text) else { continue }
                    time = parsedTime
                case 1:
                    route = text
                case 2:
                    guard let unwrappedPlatform = Int(text) else { continue }
                    platform = unwrappedPlatform
                case 3:
                    switch text {
                    case let text where text.contains(GoService.VehicleType.bus.rawValue):
                        type = .bus
                    case let text where text.contains(GoService.VehicleType.train.rawValue):
                        type = .train
                    default:
                        continue
                    }
                default:
                    assertionFailure("Frigg off lahey")
                }
            }
            guard let unwrappedTime = time,
                let unwrappedRoute = route,
                let unwrappedType = type else { continue }
            dataSource.append(GoService(vehicleType: unwrappedType, route: unwrappedRoute, departureTime: unwrappedTime, platform: platform))
        }
    }
}

extension String {
    
    /// http://stackoverflow.com/a/39344394/2236290
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        
        let attributedOptions: [String : Any] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}

extension DateFormatter {
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()
}
