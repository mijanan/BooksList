//
//  DetailViewController.swift
//  BooksList
//
//  Created by Janarthanan on 13/08/24.
//

import UIKit
import Combine
import UIImageColors

class DetailViewController: UIViewController {
    

    
    var apiService: APIService?
    var urlString: String?
    
    var favouritesManager: FavouritesManager
    
    var coreDataService: CoreDataService
    var book: Book?
    
    
    
    private let topBg: UIView = UIView()
    private let coverImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private let authorLabel: UILabel = UILabel()
    private let descTextView: UITextView = UITextView()
    private let publishedOn: UILabel = UILabel()
    private let favouriteButton: UIButton = UIButton()
    private let progress: UIActivityIndicatorView = UIActivityIndicatorView()
    
    
    private var isFavourite: Bool = false
    private var id: String = ""
    private var isCustom: Bool = false
    
    var bookUpdated: ((String) -> Void)?

    
    init(apiService: APIService, coreDataService: CoreDataService, favouritesManager: FavouritesManager, urlString: String) {
        self.apiService = apiService
        self.urlString = urlString
        self.favouritesManager = favouritesManager
        self.coreDataService = coreDataService
        super.init(nibName: nil, bundle: nil)

    }
    
    init(coreDataService: CoreDataService, favouritesManager: FavouritesManager, book: Book) {
        self.coreDataService = coreDataService
        self.favouritesManager = favouritesManager
        self.book = book
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        // Do any additional setup after loading the view.
        
        setupUI()
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchBookDetails()
    }
    
    func fetchBookDetails() {
        guard let apiService = apiService, let urlString = urlString else {
            //load local book details
            progress.startAnimating()

            Task {
                //Sync with databse if required
                let customBooks: [CustomBook] = try await coreDataService.fetch(ofType: CustomBook.self)
                if let book = self.book, let latestBook = coreDataService.getBook(with: book.id, in: customBooks) {
                    
                    
                    self.isFavourite = latestBook.isFavourite ?? false
                    self.isCustom = latestBook.isCustom ?? false
                    self.id = latestBook.id
                    self.book = latestBook
                    //   loadBookDetails(book: self.book!)
                    print("After refreshing book title: ", self.book?.title)
                }
                
                if let book = self.book {
                    
                    self.isFavourite = book.isFavourite ?? false
                    self.isCustom = book.isCustom ?? false
                    self.id = book.id
                    
                    loadBookDetails(book: book)
                    
                    setNavigationBarItems()
                }
                
               
            }
            return
        }
        Task {
            progress.startAnimating()
            let book: Book = try await apiService.fetch(url: urlString)
            let favourites: [PublicFavourites]  =  try await coreDataService.fetch(ofType: PublicFavourites.self)
         //   print("Favourites: ", coreDataService.publicFavourites)
            book.isFavourite = doesBookExist(with: book.id, in: favourites)
            
            self.isFavourite = book.isFavourite ?? false
            self.isCustom = book.isCustom ?? false
            self.id = book.id
          //  self.book = book
            loadBookDetails(book: book)
        }
    }
    
    func loadBookDetails(book: Book) {
        if book.didColorsUpdate == nil {
            book.didColorsUpdate = { [weak self] colors in
                let (primary, secondary) = colors
                DispatchQueue.main.async {
                    self?.topBg.addGradient([primary, secondary], locations: [0.0, 0.5], frame: (self?.topBg.frame)!)

                    self?.progress.stopAnimating()

                }
            }
        }
        
        
        
        
        
        self.configure(with: book)
    }
    
    
    func setupUI() {
 
        self.view.addSubview(topBg)
        
       
        
       // topBg.backgroundColor = .red
        topBg.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.view.addSubview(progress)
        progress.translatesAutoresizingMaskIntoConstraints = false
        
        publishedOn.textAlignment = .center
        self.view.addSubview(publishedOn)
        publishedOn.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        
        
        publishedOn.numberOfLines = 3
        
        
        
        descTextView.textAlignment = .center
        descTextView.isEditable = false
        descTextView.isSelectable = false
        self.view.addSubview(descTextView)
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        
        titleLabel.font = .systemFont(ofSize: 21, weight: .bold)
        authorLabel.font = .systemFont(ofSize: 15)
        
        authorLabel.textColor = .systemGray
        
      //  favouriteButton.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 30, height: 30))
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .selected)
        favouriteButton.tintColor = .red
        favouriteButton.addTarget(self, action: #selector(toggleFavouriteButton), for: .touchUpInside)
        favouriteButton.isHidden = true
        
        self.view.addSubview(favouriteButton)
        favouriteButton.translatesAutoresizingMaskIntoConstraints = false
        
      //  favouriteButton.addTarget(self, action: #selector(toggleFavouriteBtn), for: .touchUpInside)

        
        setupConstraints()
        
       
    }
    
    @objc func toggleFavouriteButton() {
        
        isFavourite.toggle()
        favouriteButton.isSelected = isFavourite
        book?.isFavourite = isFavourite
        
        
        
        
        favouritesManager.markFavourite(id: id, isFavourite: isFavourite, isCustom: isCustom, shouldReload: true)
        
        bookUpdated?(id)
    }
    
    func setupConstraints() {
        
 
        
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.backgroundColor = .clear
        coverImageView.layer.cornerRadius = 5.0
        coverImageView.layer.masksToBounds = false
        self.view.addSubview(coverImageView)
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
 
        
        NSLayoutConstraint.activate([
 
            
            coverImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            coverImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -view.bounds.height * 0.2),
            coverImageView.widthAnchor.constraint(equalToConstant: 195),
            coverImageView.heightAnchor.constraint(equalToConstant: 250),
            
            
            topBg.topAnchor.constraint(equalTo: self.view.topAnchor),
            topBg.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            topBg.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            topBg.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: -60),
            
            
            favouriteButton.topAnchor.constraint(equalTo: topBg.bottomAnchor, constant: 15),
            favouriteButton.centerXAnchor.constraint(equalTo: self.view.trailingAnchor, constant: self.view.bounds.height * -0.065),
            favouriteButton.widthAnchor.constraint(equalToConstant: 30),
            favouriteButton.heightAnchor.constraint(equalToConstant: 30)
            
         
        ])
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, authorLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        stackView.distribution = .fillEqually
        self.view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let line = UIView()
        line.backgroundColor = .lightGray
        line.tag = 9999
        line.isHidden = true
        self.view.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
    
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 10),
            stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 60),
            
            publishedOn.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 5),
            publishedOn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            publishedOn.heightAnchor.constraint(equalToConstant: 50),
            
            line.topAnchor.constraint(equalTo: publishedOn.bottomAnchor, constant: 10),
            line.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            
            descTextView.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 10),
            descTextView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            descTextView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            descTextView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            progress.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
  

       
        if let book = book {
            
            
            configure(with: book)
        }
    }
    
    func configure(with book: Book) {
        
        favouriteButton.isHidden = false
        favouriteButton.isSelected = book.isFavourite ?? false
        
        
        self.view.viewWithTag(9999)?.isHidden = false
        
        
        
        
       
        
        loadCoverImage(book: book)

        
        titleLabel.text = book.title
        authorLabel.text = book.author
        
        
        let publishedLabelAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemGray2, //Text color
                    .font: UIFont.boldSystemFont(ofSize: 15.0), //Font, Font size
                ]
        
        let publishedValueAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemGray3, //Text color
                    .font: UIFont.systemFont(ofSize: 14.0), //Font, Font size
                ]
        
        let published = NSMutableAttributedString(string: "Published On", attributes: publishedLabelAttributes)
        let newline = NSMutableAttributedString(string: "\n", attributes: publishedLabelAttributes)

        let date = NSMutableAttributedString(string: convertISOToLocalDate(isoDateString: book.publicationDate) ?? "", attributes: publishedValueAttributes)
        
        published.append(newline)
        published.append(date)
        
        publishedOn.attributedText = published
        
        
        let descTitleAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.label, //Text color
                    .font: UIFont.boldSystemFont(ofSize: 20.0), //Font, Font size
                ]
        
        let descInfoAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.label, //Text color
                    .font: UIFont.systemFont(ofSize: 14.0), //Font, Font size
                ]
        
        let desc = NSMutableAttributedString(string: "Description", attributes: descTitleAttributes)

        let info = NSMutableAttributedString(string: book.description, attributes: descInfoAttributes)
        
        desc.append(newline)
        desc.append(newline)
        desc.append(info)
        
        descTextView.attributedText = desc
 
        

    }
    
    func setNavigationBarItems() {
        // Add a right bar button item
        
        // Create a custom view that will contain the two buttons
        let customView = UIView()
        
        // Create the first button
        let firstButton = UIButton(type: .system)
        firstButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        firstButton.addTarget(self, action: #selector(editBook), for: .touchUpInside)
        firstButton.translatesAutoresizingMaskIntoConstraints = false
        firstButton.tintColor = .systemBackground
        customView.addSubview(firstButton)
        
        // Create the second button
        let secondButton = UIButton(type: .system)
        secondButton.setImage(UIImage(systemName: "trash"), for: .normal)
        secondButton.addTarget(self, action: #selector(deleteBook), for: .touchUpInside)
        secondButton.translatesAutoresizingMaskIntoConstraints = false
        secondButton.tintColor = .systemBackground
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
        
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
    }
    
    @objc func editBook() {
        let interface = AddCustomBookViewInterface()
        let addViewController = interface.loadAddCustomBookViewUI(viewContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, coreDataService: coreDataService, isEditing: true, book: book)
        interface.bookUpdated = { bookId in
            self.bookUpdated?(bookId)
        }
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
    
    @objc func deleteBook() {
        let alert = UIAlertController(title: "Attention", message: "Do you want to delete this book?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            if let book = self.book {
                if self.coreDataService.deleteCoverImage(at: book.cover) {
                    
                    Task {
                        _ =  try await self.coreDataService.fetchCustomBooks()
                        if let bk = self.coreDataService.getCustomBook(with: book.id) {
                            self.bookUpdated?(bk.id!)
                            self.coreDataService.delete(record: bk)
                            DispatchQueue.main.async {
                                
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }

            }
        }))
        self.present(alert, animated: true)
    }
    
    func loadCoverImage(book: Book) {
        
        guard let apiService = apiService else {
            //load local book cover image
            if let book = self.book {
                do {
                    let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileURL = documentsURL.appendingPathComponent(book.cover)
                    let imageData = try Data(contentsOf: fileURL)
                    let image = UIImage(data: imageData)
                    book.coverImage = image
                }
                catch {
                    debugPrint("Error while loading local cover image...", error.localizedDescription)
                }
                self.coverImageView.image = book.coverImage
                let progress = self.coverImageView.viewWithTag(8888) as? UIActivityIndicatorView
                progress?.stopAnimating()
                    
            }
            return
        }
        
        Task {
            do {
                let image: UIImage? = try await apiService.fetchImageFrom(url: book.cover)
                book.coverImage = image
                self.coverImageView.image = book.coverImage
                let progress = self.coverImageView.viewWithTag(8888) as? UIActivityIndicatorView
                progress?.stopAnimating()
                
                
                        
            }
            catch {
                debugPrint("Error while fetching image...", error.localizedDescription, book.id, book.cover)
            }
        }
    }
    
    func doesBookExist(with id: String, in favourites: [PublicFavourites]) -> Bool {
      
        return favourites.contains { $0.id! == id }
    }
    
    func convertISOToLocalDate(isoDateString: String) -> String? {
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
            return localDateString
        }
        
        // Return nil if the date conversion fails
        return nil
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIView {
   func addGradient(_ colors: [UIColor], locations: [NSNumber], frame: CGRect = .zero) {

      // Create a new gradient layer
      let gradientLayer = CAGradientLayer()
      
      // Set the colors and locations for the gradient layer
      gradientLayer.colors = colors.map{ $0.cgColor }
      gradientLayer.locations = locations

      // Set the start and end points for the gradient layer
      gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
      gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)

      // Set the frame to the layer
      gradientLayer.frame = frame

      // Add the gradient layer as a sublayer to the background view
      layer.insertSublayer(gradientLayer, at: 0)
   }
}
