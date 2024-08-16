//
//  CoreSavedLocation+CoreDataProperties.swift
//  
//
//  Created by Janarthanan Mirunalini on 07/05/24.
//
//

import Foundation
import CoreData


extension CustomBook {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomBook> {
        return NSFetchRequest<CustomBook>(entityName: "CustomBook")
    }

    @NSManaged public var name: String
    @NSManaged public var id: UUID
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var savedat: Double

}
