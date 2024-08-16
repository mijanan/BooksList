//
//  Book.swift
//  BooksList
//
//  Created by Janarthanan on 12/08/24.
//

import Foundation
import UIKit

class Book: Codable, Identifiable {
    
    var id: String                 //the ID of the book
    var title: String           //the title of the book
    var author: String          //the name of the author
    var description: String     //a short description of the book
    var cover: String           //a url pointing to the cover image of the book
    var publicationDate: String // publication date in ISO format
    var isFavourite: Bool? = false // whether book marked as favourite or not; Default: false
    var isCustom: Bool? = false // whether book marked as custom or not; Default: false
    var coverImage: UIImage? {
        didSet {
            coverImage?.getColors { colors in
                guard let colors = colors else { return }
                
                self.colors = (colors.primary, colors.secondary)
                self.didColorsUpdate?(self.colors!)
                // Insert the gradient layer at the bottom of the view's layer stack
                
            }
        }
    }
    var colors: (UIColor, UIColor)?
    
    var didColorsUpdate: (((UIColor, UIColor)) -> Void)?
    
    
    init(id: String, title: String, author: String, description: String, cover: String, publicationDate: String, isFavourite: Bool? = nil, isCustom: Bool? = nil, coverImage: UIImage? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.cover = cover
        self.publicationDate = publicationDate
        self.isFavourite = isFavourite
        self.isCustom = isCustom
        self.coverImage = coverImage
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case description
        case cover
        case publicationDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        self.id = String(id)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.description = try container.decode(String.self, forKey: .description)
        self.cover = try container.decode(String.self, forKey: .cover)
        self.publicationDate = try container.decode(String.self, forKey: .publicationDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = try encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
        try container.encode(description, forKey: .description)
        try container.encode(cover, forKey: .cover)
        try container.encode(publicationDate, forKey: .publicationDate)
     
    }

}

extension Book {
    convenience init(with customBook: CustomBook) {
        self.init(id: customBook.id ?? String("\(UUID())"), title: customBook.title ?? "", author: customBook.author ?? "", description: customBook.desc ?? "", cover: customBook.cover ?? "", publicationDate: customBook.publicationDate ?? "", isFavourite: customBook.isFavourite, isCustom: customBook.isCustom)
    }
}



