import UIKit

struct Property {
    let title: String
    let address: String
    let price: String
    let rooms: String
    let image: UIImage?
}

class HomeViewController: UIViewController {
    
    private var properties: [Property] = [
        Property(title: "Modern apartment", address: "Central", price: "$1.200.000", rooms: "2 rooms", image: UIImage(named: "sample1")),
        Property(title: "Single-family home", address: "Suburbia", price: "$875.000", rooms: "4 rooms", image: UIImage(named: "sample2")),
        Property(title: "Spacious condo", address: "Downtown", price: "$950.000", rooms: "3 rooms", image: UIImage(named: "sample3")),
        Property(title: "Ranch-style house", address: "Suburbia", price: "$780.000", rooms: "3 rooms", image: UIImage(named: "sample4"))
    ]
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    private let distanceButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("+ 0 km ▾", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let priceSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 500000
        slider.maximumValue = 2000000
        slider.value = 1200000
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let roomsLabel: UILabel = {
        let label = UILabel()
        label.text = "Rooms: Any"
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Properties"
        
        setupMenuButton()
        setupFilters()
        setupCollectionView()
    }
    
    private func setupMenuButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(openMenu)
        )
    }
    
    private func setupFilters() {
        view.addSubview(searchBar)
        view.addSubview(distanceButton)
        view.addSubview(priceSlider)
        view.addSubview(roomsLabel)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: distanceButton.leadingAnchor, constant: -8),
            
            distanceButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            distanceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            distanceButton.widthAnchor.constraint(equalToConstant: 80),
            
            priceSlider.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            priceSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            priceSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            roomsLabel.topAnchor.constraint(equalTo: priceSlider.bottomAnchor, constant: 8),
            roomsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.frame.width / 2) - 20, height: 220)
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(PropertyCell.self, forCellWithReuseIdentifier: "PropertyCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: roomsLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func openMenu() {
        let alert = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Dashboard", style: .default, handler: { _ in
            let dashVC = DashboardViewController()
            self.navigationController?.pushViewController(dashVC, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return properties.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PropertyCell", for: indexPath) as? PropertyCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: properties[indexPath.row])
        return cell
    }
}

class PropertyCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let priceLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.numberOfLines = 1
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        priceLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, priceLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            stack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
    func configure(with property: Property) {
        imageView.image = property.image ?? UIImage(systemName: "house")
        titleLabel.text = property.title
        subtitleLabel.text = "\(property.rooms) • \(property.address)"
        priceLabel.text = property.price
    }
}



