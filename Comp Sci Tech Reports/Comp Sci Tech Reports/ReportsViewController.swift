//
//  ReportsViewController.swift
//  Comp Sci Tech Reports
//
//  Created by Finnigan, Alexander on 02/11/2018.
//  Copyright © 2018 Finnigan, Alexander. All rights reserved.
//

import UIKit
import CoreData

// Structure that will store details of each report
struct techReport: Decodable {
    let year: String
    let id: String
    let owner: String?
    let authors: String
    let title: String
    let abstract: String?
    let pdf: URL?
    let comment: String?
    let lastModified: String?
}

// Structure that will store all of the reports
struct technicalReports: Decodable{
    let techreports: [techReport]
    
}

// This class will be the main view of the app which can take the user to any of the report pages.
class ReportsViewController: UITableViewController {
	
	// variable to reference the TableView
    @IBOutlet var table: UITableView!
	
	// arrays used to store the reports
    var reports = [techReport]()
    var orderedReports = [techReport]()
	
	// arrays used to store title and author for the cells; and year to sort sections.
	var reportTitle = [String]()
	var authors = [String]()
	var year = [String?]()
	
	// This is the array that will be used to populate the entire table with each section being the
	// year that the report was done.
	var sectionedReports = [(year: String, report: [techReport])]()
	
	// These variable will be used for fetching, storing and deleting the saved reports in the Core
	// Data.
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var context: NSManagedObjectContext?
	var entity: NSEntityDescription?
	var newFavs: NSManagedObject?
	
	// This is the first function that will be called. It will initialise any needed variables and
	// also decode the JSON file from the internet.
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Initialise variables used for persistent storage.
		context = appDelegate.persistentContainer.viewContext
		entity = NSEntityDescription.entity(forEntityName: "Favourites", in: context!)!
		newFavs = NSManagedObject(entity: entity!, insertInto: context)
		
		// Establish connection with the website containing the JSON file.
		if let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/techreports/data.php?class=techreports") {
			let session = URLSession.shared

			session.dataTask(with: url) { (data, response, err) in

				guard let jsonData = data else { return }
				do{
					//Decodes JSON file
					let decoder = JSONDecoder()
					let reportList = try decoder.decode(technicalReports.self, from: jsonData)
					self.reports = reportList.techreports
					
					// Sorts reports descending by year, and then by id
					self.orderedReports = self.reports.sorted{
						if $0.year != $1.year {
							return $0.year > $1.year
						} else {
							return Int($0.id)! < Int($1.id)!
						}
					}
					
					// Populates arrays for titles, abstracts and years
					self.populateData()
					
					// Create an array that only contains unique years
					var years = [String]()
					var element = 0
					years.append(self.orderedReports[element].year)
					for i in 0..<self.orderedReports.count {
						if years[element] != self.orderedReports[i].year {
							years.append(self.orderedReports[i].year)
							element += 1
						}
					}
					
					// Populate dictionary that sorts reports and collects them by year
					for i in 0..<years.count {
						var reportArray = [techReport]()
						for j in 0..<self.orderedReports.count {
							if years[i] == self.orderedReports[j].year {
								reportArray.append(self.orderedReports[j])
							}
						}
						self.sectionedReports.append((year: years[i], report: reportArray))
					}
					
					// Load UI
					DispatchQueue.main.async {
						self.table.reloadData()
					}
					
					
				} catch let jsonErr {
					print("Error decoding JSON", jsonErr)
				}
				}.resume()
		}
    }
	
	// Sets up the number of sections depending on how many unique years there are.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionedReports.count
    }
	
	// Adds the year titles for each header in the table.
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sectionedReports[section].year
	}
	
	// Sets up the number of rows inside each section.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionedReports[section].report.count
    }
	
	// Populates each individual cell inside a section. It will also check if the report in that
	// cell was saved as a favourite and if so, create a 'tick' icon on the cell.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Create reusable variable for a cell.
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
		
		// Add title of the report and the authors name to the cell.
		cell.textLabel?.text = sectionedReports[indexPath.section].report[indexPath.row].title
		cell.detailTextLabel?.text = sectionedReports[indexPath.section].report[indexPath.row].authors
		
		// Creates a unique identifier for that report so it can be used as a reference inside the
		// Core Data.
		let yearID = (sectionedReports[indexPath.section].report[indexPath.row].year) + (sectionedReports[indexPath.section].report[indexPath.row].id)
		
		// Checks the Core Data to see if this report has been saved.
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Favourites")
		request.predicate = NSPredicate(format: "yearID = %@", yearID)
		request.returnsObjectsAsFaults = false
		do {
			let results = try context?.fetch(request)
			
			if (results?.count)! > 0 {
				
				let result = results?[0] as! Favourites
				
				// If it has found this report, it will add a 'tick' to show that it was saved.
				if let _ = result.yearID {
					cell.accessoryType = .checkmark
				}
			}
		} catch {
			print("Failed")
		}
		
		// Display the cell with the given information.
        return cell
    }
	
	// Creates variables that will allow the specific report to be sent to the report page.
	var selectedSec: Int?
	var selectedRow: Int?
	
	// Sets variables and performs the segue.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		selectedSec = indexPath.section
		selectedRow = indexPath.row
        performSegue(withIdentifier: "toReport", sender: nil)
    }
	
	// Sends the current instance of variables to be used inside the report page.
	// These are the report, the newFavs object to allows inserting new data and context so Core Data
	// can be accessed inside that view.
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "toReport" {
			// Create new instance to send to.
			let viewController = segue.destination as! ViewController
			
			// Send variables to overwrite ones currently initialised inside that view.
			viewController.report = sectionedReports[selectedSec!].report[selectedRow!]
			viewController.newFavs = newFavs
			viewController.context = context
		}
	}
	
	// When the user returns to the main view, it will refresh the table data.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		table.reloadData()
    }
	
	// Populates the arrays for the titles, authors and years to be used when creating the table.
	func populateData(){
		// Populate titles
		if reportTitle.count == 0 {
			for i in 0..<orderedReports.count {
				reportTitle.append(orderedReports[i].title)
			}
		}
		
		// Populate authors
		if authors.count == 0 {
			for i in 0..<orderedReports.count {
				authors.append(orderedReports[i].authors)
			}
		}
		
		// Populate years
		if year.count == 0 {
			for i in 0..<orderedReports.count {
				year.append(orderedReports[i].year)
			}
		}
	}
}
