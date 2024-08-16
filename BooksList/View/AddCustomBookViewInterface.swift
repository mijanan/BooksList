//
//  AddCustomBookViewInterface.swift
//  BooksList
//
//  Created by Janarthanan on 14/08/24.
//

import Foundation
import SwiftUI
import CoreData

@objc
class AddCustomBookViewInterface: NSObject {
    
    var bookUpdated: ((String) -> Void)?

 
    func loadAddCustomBookViewUI(viewContext: NSManagedObjectContext, coreDataService: CoreDataService? = nil, isEditing: Bool = false, book: Book? = nil) -> UIViewController{
        var add = AddCustomBookView(viewContext: viewContext, coreDataService: coreDataService, isEditing: isEditing, book: book)
       // details.shipName = name
        add.bookUpdated = { bookId in
            self.bookUpdated?(bookId)
        }
        return UIHostingController(rootView: add)
    }
}
