//
//  AddCustomBookView.swift
//  BooksList
//
//  Created by Janarthanan on 14/08/24.
//

import SwiftUI
import CoreData

struct AddCustomBookView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    var viewContext: NSManagedObjectContext
    
    var coreDataService: CoreDataService?
    
    var isEditing: Bool = false
    
    var bookUpdated: ((String) -> Void)?


    
    var book: Book? {
        didSet {
            if let book = book {
                configure(with: book)
            }
        }
    }
    
    
    
    @State private var title: String = ""
    
    @State private var author: String = ""
    
    @State private var desc: String = ""
    
    @State private var publicationDate: Date = Date()
    
    @State private var coverImage: UIImage? = UIImage(systemName: "square.and.arrow.up") {
        didSet {
            hasPickedImage = true
        }
    }
    
    @State private var hasPickedImage: Bool = false
    
    @State private var showImagePicker: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    if !hasPickedImage {
                        Image(uiImage: coverImage!)
                            .frame(width: 145, height: 195)
                            .background(Color(red: 0.961, green: 0.965, blue: 0.973))
                            .cornerRadius(10.0)
                    }
                    else {
                        Image(uiImage: coverImage!)
                            .scaledToFill()
                            .frame(width: 145, height: 195)
                            .background(Color(red: 0.961, green: 0.965, blue: 0.973))
                            .cornerRadius(10.0)
                    }
                        
                    
                    
                }
                
                .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text("Title of the book")
                    
                    
                    CustomTextFieldView(textInput: $title, placeHolderText: "Enter title", padding: EdgeInsets(top: 8, leading: 50, bottom: 8, trailing: 50), textAlignment: .center)
                }
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text("Author of the book")
                    
                    
                    CustomTextFieldView(textInput: $author, placeHolderText: "Enter author name", padding: EdgeInsets(top: 8, leading: 50, bottom: 8, trailing: 50), textAlignment: .center)
                }
                .padding(.top, 5)
                
                DatePicker("Publication Date",
                           selection: $publicationDate,
                           displayedComponents: .date)
                .onAppear {
                    
                    
                }
                .padding(.top, 15)
                
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text("Description")
                    
                    MultilineTextView(text: $desc)
                        .frame(height: 200)
                }
                .padding(.top, 5)
                
                HStack(spacing: 15) {
                    
                    Button {
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8.0)
                                .frame(width: 80, height: 40)
                            Text("Cancel")
                                .foregroundColor(.white)
                        }
                        
                    }
                    
                    Button {
                        Task {
                            if !isEditing {
                                saveBook()
                            } 
                            else {
                                updateBook()
                            }
                        }
                    } label: {

                        ZStack {
                            RoundedRectangle(cornerRadius: 8.0)
                                .frame(width: 80, height: 40)
                            Text(isEditing ? "Update" : "Save")
                                .foregroundColor(.white)
                        }
                      
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
        }
        .onAppear {
            debugPrint("Loaded book: ", book)
            if let book = book {
                configure(with: book)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $coverImage) { uiImage in
                hasPickedImage = true
            }
                
        }
        
    }
    
    private func configure(with book: Book) {
        DispatchQueue.main.async {
            title = book.title
            author = book.author
            publicationDate = convertISOToLocalDate(isoDateString: book.publicationDate)
            desc = book.description
            do {
                let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileURL = documentsURL.appendingPathComponent(book.cover)
                let imageData = try Data(contentsOf: fileURL)
                let image = UIImage(data: imageData)
                coverImage = image
                
                hasPickedImage = true
                
                
            }
            catch {
                debugPrint("Error while setting local image...", book.id)
            }
        }
    }
    
    
    
    private func saveBook() {
        if let coreDataService = coreDataService {
            coreDataService.addNewBook(title: title, author: author, desc: desc, coverImage: coverImage,  publicationDate: publicationDate, completion: { result in
                switch result {
                case .success(let id):
                    self.bookUpdated?(id)
                    DispatchQueue.main.async {
                        
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    
                    
                case .failure(let error):
                    debugPrint("Book not added: ", error.localizedDescription)
                    
                case .none:
                    break
                }
            })
        }
        
    }
    
    private func updateBook() {
        if let coreDataService = coreDataService, let book = book {
            coreDataService.updateBook(with: book.id, title: title, author: author, desc: desc, coverImage: coverImage,  publicationDate: publicationDate, completion: { result in
                switch result {
                case .success(let updated):
                    self.bookUpdated?(book.id)
                    DispatchQueue.main.async {
                       
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    
                    
                case .failure(let error):
                    debugPrint("Book not updated: ", error.localizedDescription)
                    
                case .none:
                    break
                }
            })
        }
    }
    
    private func convertDateToISOFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Use the device's timezone if required
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"  // ISO 8601 format

        let isoDateString = dateFormatter.string(from: date) + ".000Z"
        return isoDateString
    }
    
    private func convertISOToLocalDate(isoDateString: String) -> Date {
        // 1. Create an ISO8601DateFormatter to parse the ISO date string
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 2. Convert the ISO string to a Date object
        if let date = isoFormatter.date(from: isoDateString) {
            
            // 3. Create a DateFormatter to convert the Date object to a local date string
            let localFormatter = DateFormatter()
            localFormatter.dateStyle = .medium // Customize as needed
            localFormatter.timeStyle = .none // Customize as needed
            localFormatter.locale = Locale.current // Use the current locale
            localFormatter.timeZone = TimeZone.current // Use the current time zone
            
            // 4. Convert the Date object to a local date string
            let localDateString = localFormatter.string(from: date)
            
            return localFormatter.date(from: localDateString) ?? Date()
        }
        
        // Return nil if the date conversion fails
        return Date()
    }
    

}

#Preview {
    AddCustomBookView(viewContext: NSManagedObjectContext())
}
