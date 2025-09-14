import UIKit

final class PropertyDetailViewController: UIViewController {
    
    private let propertyID: Int
    private var imageURLs: [URL] = []
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let titleLabel = UILabel()
    private let addressLabel = UILabel()
    private let priceLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    private var collectionView: UICollectionView!
    
    // MARK: - Init
    init(propertyID: Int) {
        self.propertyID = propertyID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Property Details"
        
        setupUI()
        fetchDetails()
        fetchImages()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // ScrollView + Stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .leading
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Labels
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        addressLabel.font = .systemFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = .secondaryLabel
        priceLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        priceLabel.textColor = .systemBlue
        
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.textColor = .label
        descriptionLabel.numberOfLines = 0
        
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(addressLabel)
        contentStack.addArrangedSubview(priceLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        
        // CollectionView layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: view.frame.width/2 - 30, height: 160)
        layout.sectionInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(PropertyImageCell.self, forCellWithReuseIdentifier: PropertyImageCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        contentStack.addArrangedSubview(collectionView)
        collectionView.heightAnchor.constraint(equalToConstant: 400).isActive = true
    }
    
    // MARK: - API Calls
    private func fetchDetails() {
        PropertyAPI.getPropertyDetails(id: propertyID) { [weak self] result in
            switch result {
            case .success(let property):
                DispatchQueue.main.async {
                    self?.titleLabel.text = property.title
                    self?.addressLabel.text = property.address
                    self?.priceLabel.text = "€\(property.price)"
                    self?.descriptionLabel.text = property.description
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert("Errore caricamento dettagli: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchImages() {
        PropertyAPI.getImages(for: propertyID) { [weak self] result in
            switch result {
            case .success(let urls):
                DispatchQueue.main.async {
                    self?.imageURLs = urls
                    self?.collectionView.reloadData()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert("Errore caricamento immagini: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Alert
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CollectionView
extension PropertyDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PropertyImageCell.reuseID,
            for: indexPath
        ) as! PropertyImageCell
        cell.configure(with: imageURLs[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let viewer = PanoramaViewerViewController()
        viewer.panoramaImageURL = imageURLs[indexPath.item]
        viewer.modalPresentationStyle = .fullScreen
        present(viewer, animated: true)
    }
}

// MARK: - Cell
final class PropertyImageCell: UICollectionViewCell {
    static let reuseID = "PropertyImageCell"
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                DispatchQueue.main.async { self.imageView.image = img }
            }
        }
    }
}


