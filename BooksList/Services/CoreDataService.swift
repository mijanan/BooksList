//
//  CoreDataService.swift
//  BooksList
//
//  Created by Janarthanan Mirunalini on 13/08/24.
//

import Foundation
import CoreData
import UIKit

class CoreDataService: ObservableObject {
    @Published var customBooks: [CustomBook] = []
    
    @Published var publicFavourites: [PublicFavourites] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Getting particular record
    func getBook(with id: String, in customBooks: [CustomBook]) -> Book? {
        if let customBook = customBooks.first(where: { $0.id == id }) {
            return Book(with: customBook)
        }
        return nil
    }
    
    func getCustomBook(with id: String) -> CustomBook? {
        return customBooks.first(where: { $0.id == id })
    }
    
    func getFavourite(with id: String, in favourites: [PublicFavourites]) -> PublicFavourites? {
        return favourites.first(where: { $0.id == id })
    }
    

    
    
    // MARK: - Fetching records
    func fetchPublicFavourites() async throws {
        self.publicFavourites = try await fetch(ofType: PublicFavourites.self)
        
    }
    
    func fetchCustomBooks() async throws {
        self.customBooks = try await fetch(ofType: CustomBook.self)
        
    }
    
    func fetch<T: NSManagedObject>(ofType: T.Type) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchRecords(ofType: T.self) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func fetchRecords<T: NSManagedObject>(ofType type: T.Type, completion: @escaping ((Result<[T], Error>) -> Void)) {

            // Create a fetch request for the entity
        let fetchRequest = T.fetchRequest()  as! NSFetchRequest<T>
    
        context.perform {
            do {
                let records = try self.context.fetch(fetchRequest)
                completion(.success(records))
            }
            catch {
                completion(.failure(error))
            }
        }
    }
    
    //MARK: - Managing records
    func addNewBook(title: String, author: String, desc: String, coverImage: UIImage?, publicationDate: Date, completion: @escaping ((Result<String, Error>?) -> Void))   {
        
        let newBook = CustomBook(context: context)
        newBook.id = String("\(UUID())")
        newBook.title = title
        newBook.author = author
        newBook.publicationDate = convertDateToISOFormat(date: publicationDate)
        newBook.desc = desc
        
        if !updateCoverImage(bookId: newBook.id!, coverImage: coverImage) {
            completion(.failure(ResponseError.message(nil)))
        }
        
        newBook.cover = newBook.id! + ".png"
        newBook.isCustom = true
        
        do {
            try context.save()
            print("Saved book successfully...", newBook.cover)
            reloadCustomBooks()
            completion(.success(newBook.id!))
            
        } catch {
            print("Failed to save book: \(error.localizedDescription)")
            completion(.failure(error))
        }
        
    }
    
    func reloadCustomBooks()
    {
        Task {
            try await fetchCustomBooks()
        }
    }
    
    func addPublicFavourite(id: String, completion: @escaping ((Result<Bool, Error>?) -> Void))   {
        let favourite = PublicFavourites(context: context)
        favourite.id = id
        do {
            try context.save()
            print("Saved favourite successfully...", favourite.id)
            completion(.success(true))
            
        } catch {
            print("Failed to save favourite: \(error.localizedDescription)")
            completion(.failure(error))
        }
        
    }
    

   
    func updateBook(with id: String, title: String, author: String, desc: String, coverImage: UIImage?, publicationDate: Date, completion: @escaping ((Result<Bool, Error>?) -> Void))   {
        
        Task {
            let customBooks: [CustomBook] = try await fetch(ofType: CustomBook.self)
           // self.customBooks = customBooks
            do {
                // Fetch the results
                
                
                if let bookToUpdate = customBooks.first(where: { $0.id == id }) {
                    // Modify the object
                    bookToUpdate.title = title
                    bookToUpdate.author = author
                    bookToUpdate.desc = desc
                    bookToUpdate.publicationDate = convertDateToISOFormat(date: publicationDate)
                    
                    // Save the context
                    try context.save()
                    print("Book  updated successfully!")
                    if !updateCoverImage(bookId: id, coverImage: coverImage) {
                        completion(.failure(ResponseError.message(nil)))
                        return
                    }
                    reloadCustomBooks()
                    completion(.success(true))
                    return
                } else {
                    print("Book not found.")
                    completion(.failure(ResponseError.message(nil)))
                    return
                }
                
            } catch {
                print("Failed to update book: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
        }
    }
    

    


    func delete<T: NSManagedObject>(record: T) {

            do {

                context.delete(record)
                try context.save()
                //reloadCustomBooks()
                print("Record deleted successfully...")
            }
            catch {
                print("ERROR while deleting record...", error.localizedDescription)
            }
    }
    
    func markAsFavourite(with id: String, isFavourite: Bool, completion: @escaping ((Result<Bool, Error>?) -> Void))   {
        
        Task {
            let customBooks: [CustomBook] = try await fetch(ofType: CustomBook.self)

            do {
                // Fetch the results
                
                
                if let bookToUpdate = customBooks.first(where: { $0.id == id }) {
                    // Modify the object
                    bookToUpdate.isFavourite = isFavourite
                    
                    // Save the context
                    try context.save()
                    
                    completion(.success(true))
                    return
                } else {
                    print("Book not found.")
                    completion(.failure(ResponseError.message(nil)))
                    return
                }
                
            } catch {
                print("Failed to update book: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
        }
    }



    // MARK: - Cover Image Handling
    
    private func saveImageToLocalDirectory(image: UIImage, imageName: String) -> URL? {
        // Convert the image to JPEG or PNG Data
        guard let imageData = image.pngData() else {
            print("Error converting image to data")
            return nil
        }

        // Get the path to the Documents directory
        let fileManager = FileManager.default
        do {
            // Get the URL for the Documents directory
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            // Create a file name with the provided image name and ".jpg" extension
            let fileURL = documentsURL.appendingPathComponent("\(imageName).png")
            
            // Write the image data to the file
            try imageData.write(to: fileURL)
            
            print("Image saved successfully at: \(fileURL)")
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    private func updateCoverImage(bookId: String, coverImage: UIImage?) -> Bool{
        if let coverImage =  coverImage {
            guard let fileURL = saveImageToLocalDirectory(image: coverImage, imageName: bookId) else {
                print("Failed to save iamge: ", bookId)
                return false
            }
            return true
        }
        return false
    }
    
    func deleteCoverImage(at path: String) -> Bool {
        do {
            let fileManager = FileManager.default
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsURL.appendingPathComponent(path)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                print("Successfully removed cover image...")
            }
            return true

        }
        catch {
            print("Error while deleting cover image...", error.localizedDescription)
        }
        return false
    }

    
    //MARK: - Utilities

    private func convertDateToISOFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Use the device's timezone if required
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"  // ISO 8601 format

        let isoDateString = dateFormatter.string(from: date) + ".000Z"
        return isoDateString
    }
}
