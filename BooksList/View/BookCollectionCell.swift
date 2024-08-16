//
//  BookListCell.swift
//  BooksList
//
//  Created by Janarthanan  on 13/08/24.
//

import Foundation
import UIKit

@MainActor
class BookCollectionCell: UICollectionViewCell {
    private let coverImageView = UIImageView()
    private let titleLabel = TopAlignedLabel()
    private let favouriteButton = UIButton()
    
    var isFavourite: Bool = false
    var isCustom: Bool = false
    
    var didChangeIsFavourite: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        
       // self.contentView.backgroundColor = .yellow

        
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .center
        
      //  favouriteButton.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 30, height: 30))
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .selected)
        favouriteButton.tintColor = .red
        favouriteButton.addTarget(self, action: #selector(toggleFavouriteBtn), for: .touchUpInside)
        
        contentView.addSubview(favouriteButton)
        favouriteButton.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            favouriteButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            favouriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            favouriteButton.heightAnchor.constraint(equalToConstant: 22),
            favouriteButton.widthAnchor.constraint(equalToConstant: 22),
            
            
            belowCover.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            belowCover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            belowCover.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            belowCover.heightAnchor.constraint(equalToConstant: 80),
            
            overCover.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            overCover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overCover.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overCover.heightAnchor.constraint(equalToConstant: 20),
            
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            coverImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 100),
            
            progress.centerXAnchor.constraint(equalTo: coverImageView.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor)
        ])

        
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        stackView.distribution = .equalSpacing
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 5),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure(with book: Book, apiService: APIService? = nil) {
                
        let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16.0), //Font, Font size
                ]
        let newline = NSMutableAttributedString(string: "\n", attributes: titleAttributes)

        let authorAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12.0), //Font, Font size
                ]
        
        let title = NSMutableAttributedString(string: book.title, attributes: titleAttributes)
        let author = NSMutableAttributedString(string: book.author, attributes: authorAttributes)

        
        title.append(newline)
        title.append(author)
        
        titleLabel.attributedText = title
        
        
        
        
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
