//
//  FavouritesManager.swift
//  BooksList
//
//  Created by Janarthanan on 15/08/24.
//

import Foundation


class FavouritesManager {
    
    let coreDataService: CoreDataService
    
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
    }
    
    func markFavourite(id: String, isFavourite: Bool, isCustom: Bool, shouldReload: Bool = false) {
        if isCustom {
            self.coreDataService.markAsFavourite(with: id, isFavourite: isFavourite) { _ in }
        }
        else {
            if isFavourite {
                self.coreDataService.addPublicFavourite(id: id) { _ in }
            } 
            else {
                Task {
                    let favourites: [PublicFavourites] = try await self.coreDataService.fetch(ofType: PublicFavourites.self)
                    if let favourite = self.coreDataService.getFavourite(with: id, in: favourites) {
                        self.coreDataService.delete(record: favourite)
                        
                        
                        
                    }
                }
            }
        }
        
        //Reload Favourites
        Task {
            if shouldReload {
                _ =  try await coreDataService.fetchPublicFavourites()
            }
        }
    }
}
