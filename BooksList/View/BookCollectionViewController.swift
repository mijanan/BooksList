//
//  BookCollectionViewController.swift
//  BooksList
//
//  Created by Janarthanan  on 15/08/24.
//

import UIKit
import Combine


class BookCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, Bindable {
    
    private let reuseIdentifier: String = "BookCollectionCell"
    
    let numberOfColumns: Int = 3 // Set the desired number of columns
    let cellSpacing: CGFloat = 10 // Spacing between cells
    
    var apiService: APIService?
    var favouritesManager: FavouritesManager?
    var booksManager: BooksManager?
    
    var delegate: Selectable?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Create a layout for the collection view
        let layout = UICollectionViewFlowLayout()
       // layout.minimumInteritemSpacing = 10
      //  layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 40, right: 10)
        
        // Initialize UICollectionViewController with the layout
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(BookCollectionCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (booksManager?.books.count ?? 0)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BookCollectionCell
    
        // Configure the cell
        if let book = booksManager?.books[indexPath.row] {
            cell.configure(with: book, apiService: apiService)
            
            cell.didChangeIsFavourite = { isFavourite in
                
                self.favouritesManager?.markFavourite(id: book.id, isFavourite: isFavourite, isCustom: cell.isCustom)
                
            }
        }
    
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    // Configure the size for each item
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = cellSpacing * CGFloat(numberOfColumns - 1) // Total space between cells
        let totalInset = collectionView.contentInset.left + collectionView.contentInset.right // Total insets
        let availableWidth = collectionView.frame.width - totalSpacing - totalInset // Available width for cells
        let itemWidth = 150// availableWidth / CGFloat(numberOfColumns) // Calculate item width
        
        return CGSize(width: itemWidth, height: 200) // Return square cells
    }
    
    // Configure spacing between items
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // Configure spacing between lines
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 60
    }
    
    

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let book: Book = booksManager?.books[indexPath.row] {
            delegate?.didSelectBook(book: book)
        }
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    // MARK: - Binding
    func bindData() {
        if let booksManager = booksManager {
            booksManager.$books
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    if let hidden = self?.view.isHidden, !hidden {
                        print("Received updated books....Reloading collectionview now...")
                        
                        self?.collectionView.reloadData()
                    }
                }
                .store(in: &cancellables)
        }
    }

}
