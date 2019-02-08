//
//  PdfViewController.swift
//  Comp Sci Tech Reports
//
//  Created by Finnigan, Alexander on 06/11/2018.
//  Copyright © 2018 Finnigan, Alexander. All rights reserved.
//

import UIKit
import PDFKit

// This class simply displays the PDF that was selected by the user.
class PdfViewController: UIViewController {
    
    // PDF url that was given by ViewController.swift
    var pdfFile: URL?
    
    // When the page loads, it will create a PDFView to display the file.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create PDFView
        let pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        // Set contraints on the view
        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        // Output the file.
        if let document = PDFDocument(url: pdfFile!) {
            pdfView.document = document
        }
    }
}
