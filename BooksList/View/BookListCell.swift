//
//  BookListCell.swift
//  BooksList
//
//  Created by Janarthanan Mirunalini on 13/08/24.
//

import Foundation
import UIKit

@MainActor
class BookListCell: UITableViewCell {
    private let coverImageView = UIImageView()
    private let titleLabel = TopAlignedLabel()
    private let authorLabel = UILabel()
    private let favouriteButton = UIButton()
    
    var isFavourite: Bool = false
    var isCustom: Bool = false
    
    var didChangeIsFavourite: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.numberOfLines = 4
        authorLabel.font = .systemFont(ofSize: 12)
        
      //  favouriteButton.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 30, height: 30))
        favouriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favouriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        favouriteButton.tintColor = .red
        favouriteButton.addTarget(self, action: #selector(toggleFavouriteBtn), for: .touchUpInside)
        
        //contentView.addSubview(favouriteButton)
        
        setConstraints()
    }
    
    func setConstraints() {
        
        let belowCover = UILabel()
        belowCover.backgroundColor = .gray
        belowCover.layer.cornerRadius = 5.0
        belowCover.layer.masksToBounds = true
        contentView.addSubview(belowCover)
        
        belowCover.translatesAutoresizingMaskIntoConstraints = false
        
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.backgroundColor = .clear
        coverImageView.layer.cornerRadius = 5.0
        coverImageView.layer.masksToBounds = false
        contentView.addSubview(coverImageView)
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let overCover = UILabel()
        overCover.backgroundColor = UIColor(white: 1.0, alpha: 0.35)
        coverImageView.addSubview(overCover)
        overCover.layer.cornerRadius = 5.0
        overCover.layer.masksToBounds = false
        overCover.translatesAutoresizingMaskIntoConstraints = false
        
        let progress = UIActivityIndicatorView(style: .medium)
        coverImageView.addSubview(progress)
        progress.tag = 8888
        progress.startAnimating()
        progress.translatesAutoresizingMaskIntoConstraints = false

        
        
        NSLayoutConstraint.activate([
            
            
            belowCover.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            belowCover.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            belowCover.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            belowCover.heightAnchor.constraint(equalToConstant: 60),
            
            overCover.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            overCover.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            overCover.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            overCover.heightAnchor.constraint(equalToConstant: 20),
            
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            coverImageView.widthAnchor.constraint(equalToConstant: 100),
            
            progress.centerXAnchor.constraint(equalTo: coverImageView.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor)
        ])

        
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, favouriteButton])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 5
        stackView.distribution = .equalSpacing
        contentView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 20),
         //   stackView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func configure(with book: Book, apiService: APIService? = nil) {
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16.0), //Font, Font size
                ]

        let authorAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12.0), //Font, Font size
                ]
        let newline = NSMutableAttributedString(string: "\n", attributes: [
            .font: UIFont.boldSystemFont(ofSize: 5.0), //Font, Font size
        ])

        
        let title = NSMutableAttributedString(string: book.title, attributes: titleAttributes)
        let author = NSMutableAttributedString(string: book.author, attributes: authorAttributes)

        
        title.append(newline)
        title.append(newline)
        title.append(author)
        
        titleLabel.attributedText = title
        
       // authorLabel.text = book.author
        isFavourite = book.isFavourite ?? false
        isCustom = book.isCustom ?? false
        favouriteButton.isSelected = isFavourite
        if let apiService = apiService {
            Task {
                do {
                    if (book.isCustom == nil || !book.isCustom!)  {
                        let image: UIImage? = try await apiService.fetchImageFrom(url: book.cover)
                        book.coverImage = image
                    } else {
                        let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        let fileURL = documentsURL.appendingPathComponent(book.cover)
                        let imageData = try Data(contentsOf: fileURL)
                        let image = UIImage(data: imageData)
                        book.coverImage = image
                    }
                    self.coverImageView.image = book.coverImage
                    let progress = self.coverImageView.viewWithTag(8888) as? UIActivityIndicatorView
                    progress?.stopAnimating()
                }
                catch {
                    debugPrint("Error while fetching image...", error.localizedDescription, book.id, book.cover)
                }
                
            }
        }
        

    }
    
    @objc func toggleFavouriteBtn() {
        isFavourite.toggle()
        favouriteButton.isSelected = isFavourite
        self.didChangeIsFavourite?(isFavourite)
    }
}
