//
//  Fetchable.swift
//  BooksList
//
//  Created by Janarthanan on 12/08/24.
//

import Foundation
import Combine

protocol Bindable {
    
    var apiService: APIService? { get set }
    
    var favouritesManager: FavouritesManager? { get set}
    
    func bindData()
}
