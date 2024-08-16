//
//  BookViewModel.swift
//  BooksList
//
//  Created by Janarthanan on 13/08/24.
//

import Foundation
import Combine

class BooksManager: ObservableObject {
    @MainActor @Published var books: [Book] = []
    
    private var apiService: APIService
    
    private var coreDataService: CoreDataService
    
    private var cancellables = Set<AnyCancellable>()
    
    var booksUpdated: (() -> Void)?
    
    private var isFetching: Bool = false
    
    init(apiService: APIService, coreDataService: CoreDataService) {
        self.apiService = apiService
        self.coreDataService = coreDataService
        
        setupBindings()
        
        fetchAndUpdateBooks()
        
    }
    
    private func setupBindings() {
        coreDataService.$publicFavourites
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    print("Received updated favourites....")

                    self?.fetchAndUpdateBooks()
                }
                .store(in: &cancellables)
        
        coreDataService.$customBooks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    print("Received updated custom books....")

                    self?.fetchAndUpdateBooks()
                }
                .store(in: &cancellables)

    }
    
    func fetchAndUpdateBooks(enableCache: Bool = true)  {
        guard !isFetching else {
            return
        }
        isFetching = true
        Task {
            do {
                let books: [Book] = try await apiService.fetch(url: Constants.GET_URL, enableCache: enableCache)
              //  debugPrint("API books response: ", books)
                
               
                let favourites: [PublicFavourites] =  try await coreDataService.fetch(ofType: PublicFavourites.self)
                books.forEach {[weak self] book in
                    book.isFavourite = self?.doesBookExist(with: book.id, in: favourites)
                   /// print("Favourite Status: ", book.id, book.isFavourite)
                }
                
                let customBooks = try await coreDataService.fetch(ofType: CustomBook.self).map { customBook in
                    return Book(with: customBook)
                }
                
             //   debugPrint("Custom books response: ", customBooks)
                
                
                //publishing new books list to subscribers
                DispatchQueue.main.async {
                    self.books = books + customBooks
                  //  self.booksUpdated?()
                }
                
                isFetching = false
                
               //
            }
            catch {
                isFetching = false
            }
        }
    }
    
    func doesBookExist(with id: String, in favourites: [PublicFavourites]) -> Bool {
      
        return favourites.contains { $0.id == id }
    }
    
}
