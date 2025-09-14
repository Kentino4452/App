import UIKit

final class HomeViewController: UIViewController,
                                UICollectionViewDataSource,
                                UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout {
    
    // Lista immobili dal backend
    private var properties: [Property] = []
    
    // MARK: UI – top filters
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    private let distanceButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("+ 0 km", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 10
        btn.backgroundColor = .secondarySystemBackground
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let filtersCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let priceTitle = HomeViewController.makeCaptionLabel("Price range")
    private let priceSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 500_000
        s.maximumValue = 2_000_000
        s.value = 1_200_000
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private let priceMinLabel = HomeViewController.makeSmallMutedLabel("500K")
    private let priceMaxLabel = HomeViewController.makeSmallMutedLabel("2M")
    
    private let roomsTitle = HomeViewController.makeCaptionLabel("Rooms")
    private let roomsSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0      // 0 = Any
        s.maximumValue = 4      // 4 = 4+
        s.value = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private let roomsValueLabel = HomeViewController.makeSmallMutedLabel("Any")
    
    // MARK: Collection
    private var collectionView: UICollectionView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Properties"
        
        setupNavBarMenu()
        setupTopFilters()
        setupCollection()
        configureDistanceMenu()
        wireActions()
        fetchProperties()
    }
    
    // MARK: UI Builders
    private static func makeCaptionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
    
    private static func makeSmallMutedLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
    
    private func setupNavBarMenu() {
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(openMenu)
        )
        navigationItem.rightBarButtonItem = menuButton
    }
    
    private func setupTopFilters() {
        view.addSubview(searchBar)
        view.addSubview(distanceButton)
        view.addSubview(filtersCard)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: distanceButton.leadingAnchor, constant: -8),
            
            distanceButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            distanceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
        
        filtersCard.addSubview(priceTitle)
        filtersCard.addSubview(priceSlider)
        filtersCard.addSubview(priceMinLabel)
        filtersCard.addSubview(priceMaxLabel)
        filtersCard.addSubview(roomsTitle)
        filtersCard.addSubview(roomsSlider)
        filtersCard.addSubview(roomsValueLabel)
        
        NSLayoutConstraint.activate([
            filtersCard.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            filtersCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            filtersCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            priceTitle.topAnchor.constraint(equalTo: filtersCard.topAnchor, constant: 12),
            priceTitle.leadingAnchor.constraint(equalTo: filtersCard.leadingAnchor, constant: 12),
            
            priceSlider.topAnchor.constraint(equalTo: priceTitle.bottomAnchor, constant: 8),
            priceSlider.leadingAnchor.constraint(equalTo: filtersCard.leadingAnchor, constant: 12),
            priceSlider.trailingAnchor.constraint(equalTo: filtersCard.trailingAnchor, constant: -12),
            
            priceMinLabel.topAnchor.constraint(equalTo: priceSlider.bottomAnchor, constant: 2),
            priceMinLabel.leadingAnchor.constraint(equalTo: priceSlider.leadingAnchor),
            
            priceMaxLabel.centerYAnchor.constraint(equalTo: priceMinLabel.centerYAnchor),
            priceMaxLabel.trailingAnchor.constraint(equalTo: priceSlider.trailingAnchor),
            
            roomsTitle.topAnchor.constraint(equalTo: priceMinLabel.bottomAnchor, constant: 14),
            roomsTitle.leadingAnchor.constraint(equalTo: priceSlider.leadingAnchor),
            
            roomsSlider.topAnchor.constraint(equalTo: roomsTitle.bottomAnchor, constant: 8),
            roomsSlider.leadingAnchor.constraint(equalTo: priceSlider.leadingAnchor),
            roomsSlider.trailingAnchor.constraint(equalTo: priceSlider.trailingAnchor),
            roomsSlider.bottomAnchor.constraint(equalTo: roomsValueLabel.topAnchor, constant: -2),
            
            roomsValueLabel.leadingAnchor.constraint(equalTo: roomsSlider.leadingAnchor),
            roomsValueLabel.bottomAnchor.constraint(equalTo: filtersCard.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(PropertyCell.self, forCellWithReuseIdentifier: PropertyCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: filtersCard.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureDistanceMenu() {
        let actions: [UIAction] = ["+ 0 km", "+ 1 km", "+ 5 km", "+ 10 km"].map { title in
            UIAction(title: title) { [weak self] _ in
                self?.distanceButton.setTitle(title, for: .normal)
            }
        }
        distanceButton.menu = UIMenu(title: "", children: actions)
        distanceButton.showsMenuAsPrimaryAction = true
    }
    
    private func wireActions() {
        priceSlider.addTarget(self, action: #selector(priceChanged), for: .valueChanged)
        roomsSlider.addTarget(self, action: #selector(roomsChanged), for: .valueChanged)
    }
    
    @objc private func priceChanged() {
        let v = Int(priceSlider.value)
        if v >= 1_000_000 {
            priceMaxLabel.text = String(format: "%.1fM", Double(v) / 1_000_000.0)
        } else {
            priceMaxLabel.text = String(format: "%dK", v / 1_000)
        }
    }
    
    @objc private func roomsChanged() {
        let raw = Int(round(roomsSlider.value))
        roomsSlider.value = Float(raw)
        roomsValueLabel.text = raw == 0 ? "Any" : (raw == 4 ? "4+" : "\(raw)")
    }
    
    // MARK: Menu
    @objc private func openMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Dashboard", style: .default, handler: { [weak self] _ in
            let vc = DashboardViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let pop = alert.popoverPresentationController, let barButton = navigationItem.rightBarButtonItem {
            pop.barButtonItem = barButton
        }
        present(alert, animated: true)
    }
    
    // MARK: API
    private func fetchProperties() {
        PropertyAPI.getProperties { [weak self] result in
            switch result {
            case .success(let props):
                DispatchQueue.main.async {
                    self?.properties = props
                    self?.collectionView.reloadData()
                }
            case .failure(let error):
                print("Errore caricamento properties: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Collection DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        properties.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PropertyCell.reuseID, for: indexPath) as! PropertyCell
        cell.configure(with: properties[indexPath.item])
        return cell
    }
    
    // MARK: FlowLayout – 2 colonne responsive
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalHSpacing: CGFloat = 12
        let columns: CGFloat = 2
        let insets: CGFloat = 8 * 2
        let available = collectionView.bounds.width - insets - totalHSpacing
        let width = floor(available / columns)
        return CGSize(width: width, height: 230)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selected = properties[indexPath.item]
        let detail = PropertyDetailViewController(propertyID: selected.id)
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Cell
final class PropertyCell: UICollectionViewCell {
    static let reuseID = "PropertyCell"
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let priceLabel = UILabel()
    private let card = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 6
        card.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        priceLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, priceLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(card)
        card.addSubview(imageView)
        card.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            textStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            textStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with property: Property) {
        imageView.image = UIImage(systemName: "house.fill") // placeholder
        titleLabel.text = property.title
        subtitleLabel.text = property.address
        priceLabel.text = "€\(property.price)"
    }
}







