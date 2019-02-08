//
//  ViewController.swift
//  Comp Sci Tech Reports
//
//  Created by Finnigan, Alexander on 02/11/2018.
//  Copyright © 2018 Finnigan, Alexander. All rights reserved.
//

import UIKit
import PDFKit
import CoreData

// This class will be the view seen after the user has selected a report.
class ViewController: UIViewController {
    
    // Contains the report that was selected.
    var report: techReport?
    
    // Initialise variables for persistence storage use.
    var newFavs: NSManagedObject?
    var context: NSManagedObjectContext?
    
    // Used to store the unique ID of the report.
    var yearID = String()
    
    // Variable reference for the title label.
    @IBOutlet weak var reportTitle: UILabel!
    
    // Variable reference for the authors label.
    @IBOutlet weak var authors: UILabel!
    
    // Variable reference for the abstract label.
    @IBOutlet weak var abstract: UILabel!
    
    // Variable reference for the favourites switch.
    @IBOutlet weak var favSwitchContainer: UISwitch!
    
    // Variable reference for the PDF view button.
    @IBOutlet weak var viewPDFbtn: UIButton!
    
    // Adds the title, authors, abtract and PDF link for the report.
    // It also creates the unique ID for the report.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title and authors
        reportTitle.text = report!.title
        authors.text = report?.authors
        
        // Set abstract; but if there isn't one, it will display a label explaining there is no
        // abstract.
        if report?.abstract != nil {
            abstract.text = report?.abstract
        }
        
        // Create unique ID
        yearID = (report!.year + report!.id)
        
        // Checks if the report link is actually a PDF file, if not it will disable the button and
        // change it to a label saying that the report cannot be viewed.
        let checkPDF = report!.pdf?.absoluteString.suffix(3)
        if checkPDF != "pdf" {
            viewPDFbtn.isEnabled = false
            viewPDFbtn.setTitle("No PDF view", for: .normal)
        }
    }
    
    // Sends the pdf url to the next page that will show the report.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPDF" {
            let pdfViewController = segue.destination as! PdfViewController
            pdfViewController.pdfFile = report?.pdf
        }
    }
    
    // Button that takes the user to the PDF view.
    @IBAction func viewPDF(_ sender: Any){
        // Leave empty
    }
    
    // The favourite switch.
    // When turned on, it will save this report to the Core Data and keep this switch on until it is
    // turned off. If it is then turned off, the report will be deleted from Core Data and the switch
    // will be turned off.
    @IBAction func favSwitch(_ sender: Any) {
        
        // When on, save to Core Data.
        if favSwitchContainer.isOn {
            let newFav = NSEntityDescription.insertNewObject(forEntityName: "Favourites", into: context!) as! Favourites
            newFav.yearID = yearID
            saved()
            print("done array add")
        } else {
            // If switched to off, delete from Core Data and save state.
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Favourites")
            
            request.predicate = NSPredicate(format: "yearID == %@", yearID)
            
            request.returnsObjectsAsFaults = false
            do {
                let results = try context?.fetch(request)
                for object in results! {
                    context?.delete(object as! NSManagedObject)
                }
                saved()
            } catch {
                print("couldn't fetch results")
        }
            print("removed entry")
        }
    }
    
    // When the user returns to this screen, this method will check Core Data and if the report is saved
    // it will set the switch back to on. Otherwise, it will keep the switch off.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Calls fetchFav() to look for the report and if so, turn switch on.
        if fetchFav() {
            favSwitchContainer.setOn(true, animated: true)
            print("switch on")
        } else {
            // If fetchFav() couldn't find the report, turn switch off.
            favSwitchContainer.setOn(false, animated: true)
            print("switch off")
        }
    }
    
    // Searches through Core Data for the report the user is viewing and returns true if it was found,
    // or false if it was not found.
    func fetchFav() -> Bool{
        var check = false
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Favourites")
        
        request.predicate = NSPredicate(format: "yearID == %@", yearID) 
        
        request.returnsObjectsAsFaults = false
        do {
            let results = try context?.fetch(request)
            for _ in results! {
                // Found it.
                check = true
            }
        } catch {
            print("couldn't fetch results")
        }
        return check
    }
    
    // Saves the current state of the Core Data. This will be called after any inserts or deletes.
    func saved(){
        do {
            try context?.save()
            
            print("Saved")
        } catch {
            print("there was an error")
        }
    }
}

