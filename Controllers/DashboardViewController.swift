import UIKit

final class DashboardViewController: UIViewController {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Dashboard"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let addPropertyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Property", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }()

    private let propertiesCard = DashboardCard(title: "Properties Listed", value: "4")
    private let inquiriesCard  = DashboardCard(title: "Inquiries",         value: "12")
    private let salesCard      = DashboardCard(title: "Total Sales",       value: "$2,075,000")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        addPropertyButton.addTarget(self, action: #selector(openAddProperty), for: .touchUpInside)
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(addPropertyButton)
        view.addSubview(propertiesCard)
        view.addSubview(inquiriesCard)
        view.addSubview(salesCard)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addPropertyButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            addPropertyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addPropertyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            propertiesCard.topAnchor.constraint(equalTo: addPropertyButton.bottomAnchor, constant: 28),
            propertiesCard.leadingAnchor.constraint(equalTo: addPropertyButton.leadingAnchor),
            propertiesCard.trailingAnchor.constraint(equalTo: addPropertyButton.trailingAnchor),
            propertiesCard.heightAnchor.constraint(equalToConstant: 84),

            inquiriesCard.topAnchor.constraint(equalTo: propertiesCard.bottomAnchor, constant: 16),
            inquiriesCard.leadingAnchor.constraint(equalTo: propertiesCard.leadingAnchor),
            inquiriesCard.trailingAnchor.constraint(equalTo: propertiesCard.trailingAnchor),
            inquiriesCard.heightAnchor.constraint(equalTo: propertiesCard.heightAnchor),

            salesCard.topAnchor.constraint(equalTo: inquiriesCard.bottomAnchor, constant: 16),
            salesCard.leadingAnchor.constraint(equalTo: inquiriesCard.leadingAnchor),
            salesCard.trailingAnchor.constraint(equalTo: inquiriesCard.trailingAnchor),
            salesCard.heightAnchor.constraint(equalTo: propertiesCard.heightAnchor)
        ])
    }

    // Flusso corretto: prima si crea la proprietà → poi GuidedCapture(propertyID:)
    @objc private func openAddProperty() {
        let newPropertyVC = NewPropertyViewController()
        navigationController?.pushViewController(newPropertyVC, animated: true)
    }
}

// MARK: - Reusable Card
final class DashboardCard: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String, value: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        layer.cornerRadius = 14
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
