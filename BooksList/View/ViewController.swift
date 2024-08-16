//
//  ViewController.swift
//  BooksList
//
//  Created by Janarthanan on 12/08/24.
//

import UIKit
import Combine

enum Reload {
    case none
    case full
    case row(Int)
}

class ViewController: UIViewController, Selectable {
    
    // MARK: - Vars - Views & View Components
    lazy var tableViewController = BookTableViewController()
    
    lazy var collectionViewController = BookCollectionViewController()
    
    private let addButton: UIButton = UIButton()
    
    private var reloadRow: Reload =  .none
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
                     #selector(handleRefresh(_:)),
                                 for: .valueChanged)
        refreshControl.tintColor = UIColor.gray
        
        return refreshControl
    }()
    
    lazy var refreshControl_CV: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
                     #selector(handleRefresh(_:)),
                                 for: .valueChanged)
        refreshControl.tintColor = UIColor.gray
        
        return refreshControl
    }()
    
    
    
    // MARK: - Vars - View Models & Services
    private var booksManager: BooksManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let apiService: APIService = APIService()
    
    private let coreDataService: CoreDataService = CoreDataService(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
    
    private var favouritesManager: FavouritesManager?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = "Books"
        self.view.backgroundColor = .systemBackground
        
        setNavigationBarItems()
        
        setupUI()
        
        favouritesManager = FavouritesManager(coreDataService: coreDataService)
        
        
        setConstraints()
        
        debugPrint("main view loaded...")
        
        
        bindViewModel()
                
        setupBindings()
        
      //  booksManager?.fetchAndUpdateBooks()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        switch reloadRow {
            case .none:
                break
            case .full:
                if !tableViewController.view.isHidden {
                    tableViewController.tableView.reloadData()
                }
                else {
                    collectionViewController.collectionView.reloadData()
                }
            case .row(let row):
                if !tableViewController.view.isHidden {
                    self.tableViewController.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }
                else {
                    collectionViewController.collectionView.reloadItems(at:  [IndexPath(row: row, section: 0)])
                }

        }
        reloadRow = .none
    }
    
    // MARK: - Setup  Views
    private func setupUI() {
        self.view.addSubview(tableViewController.view)
        self.view.addSubview(collectionViewController.view)
        
        tableViewController.tableView.addSubview(self.refreshControl)
        collectionViewController.collectionView.refreshControl = self.refreshControl_CV


        
        addButton.setBackgroundImage(UIImage(systemName: "plus.circle"), for: .normal)
        addButton.tintColor = .black
        self.view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addCustomBook), for: .touchUpInside)
        
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints = false

    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            // Add button constraints
            addButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
            addButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            addButton.widthAnchor.constraint(equalToConstant: 35),
            addButton.heightAnchor.constraint(equalToConstant: 35),
            
            // TableView constraints
            tableViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 90),
            tableViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -25),
            

            // CollectionView Constraints
            collectionViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 90),
            collectionViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            collectionViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -25)
        ])
    }
    
    func setNavigationBarItems() {
        
        // Create a custom view that will contain the two buttons
        let customView = UIView()
        
        // Create the first button
        let firstButton = UIButton(type: .system)
        firstButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        firstButton.addTarget(self, action: #selector(showTableView), for: .touchUpInside)
        firstButton.translatesAutoresizingMaskIntoConstraints = false
        firstButton.tintColor = .label
        customView.addSubview(firstButton)
        
        // Create the second button
        let secondButton = UIButton(type: .system)
        secondButton.setImage(UIImage(systemName: "circle.grid.2x2"), for: .normal)
        secondButton.addTarget(self, action: #selector(showCollectionView), for: .touchUpInside)
        secondButton.translatesAutoresizingMaskIntoConstraints = false
        secondButton.tintColor = .label
        customView.addSubview(secondButton)
        
        // Set constraints for the buttons within the custom view
        NSLayoutConstraint.activate([
            // First button constraints
            firstButton.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            firstButton.topAnchor.constraint(equalTo: customView.topAnchor),
            firstButton.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            
            // Second button constraints
            secondButton.leadingAnchor.constraint(equalTo: firstButton.trailingAnchor, constant: 10),
            secondButton.topAnchor.constraint(equalTo: customView.topAnchor),
            secondButton.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            secondButton.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ])
        
        // Wrap the custom view in a UIBarButtonItem
        let customBarButtonItem = UIBarButtonItem(customView: customView)
        
        // Set the customBarButtonItem as the right bar button item
        self.navigationItem.rightBarButtonItem = customBarButtonItem
    }
    
    // MARK: - View Actions
    
    @objc func addCustomBook() {
        let interface = AddCustomBookViewInterface()
        let addViewController = interface.loadAddCustomBookViewUI(viewContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, coreDataService: coreDataService)
        interface.bookUpdated = { bookId in
            print("Record added/updated ...")
            let row = self.findRowIndexForBook(with: bookId)
            print("Row index for book: ", bookId, row)
            self.reloadRow = row < 0 ? .full : .row(row)
        }
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
    
//    private func checkAndUpdateIfRequired() {
//        if dataUpdated {
//            booksManager?.fetchAndUpdateBooks()
//            dataUpdated = false
//        }
//    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        booksManager?.fetchAndUpdateBooks()
        refreshControl.endRefreshing()
    }
    
    @objc func showTableView() {
        tableViewController.view.isHidden = false
        booksManager?.fetchAndUpdateBooks()
        collectionViewController.view.isHidden = true
        
    }
    
    @objc func showCollectionView() {
        collectionViewController.view.isHidden = false
        booksManager?.fetchAndUpdateBooks()
        tableViewController.view.isHidden = true
    }

    // MARK: - Bindings
    func bindViewModel() {
        booksManager = BooksManager(apiService: apiService, coreDataService: coreDataService)

    }

    func setupBindings() {
        
        tableViewController.apiService = apiService
        tableViewController.booksManager = booksManager
        tableViewController.favouritesManager = favouritesManager
        tableViewController.bindData()
        tableViewController.delegate = self
        
        collectionViewController.apiService = apiService
        collectionViewController.booksManager = booksManager
        collectionViewController.favouritesManager = favouritesManager
        collectionViewController.bindData()
        collectionViewController.delegate = self
        
        collectionViewController.view.isHidden = true

            
    }
    

    
    // MARK: - Book Selection Action
    func didSelectBook(book: Book) {
        if (book.isCustom == nil || !book.isCustom!) {
            let detailView = DetailViewController(apiService: apiService, coreDataService: coreDataService, favouritesManager: favouritesManager!, urlString: Constants.GET_URL + "/\(book.id)")
            detailView.bookUpdated = { bookId in
                let row = self.findRowIndexForBook(with: bookId)
                print("Row index for book: ", bookId, row)
                self.reloadRow = row < 0 ? .full : .row(row)
            }
            self.navigationController?.pushViewController(detailView, animated: true)
        }
        else {
            let detailView = DetailViewController(coreDataService: coreDataService, favouritesManager: favouritesManager!, book: book)
            self.navigationController?.pushViewController(detailView, animated: true)
            detailView.bookUpdated = { bookId in
                let row = self.findRowIndexForBook(with: bookId)
                print("Row index for book: ", bookId, row)
                self.reloadRow = row < 0 ? .full : .row(row)
            }
        }
    }
    
    
    private func findRowIndexForBook(with id: String) -> Int {
        
        return booksManager?.books.firstIndex { $0.id == id } ?? -1
    }

}

