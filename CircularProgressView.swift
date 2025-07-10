import UIKit

class CircularProgressView: UIView {

    private let shapeLayer = CAShapeLayer()

    private var progress: CGFloat = 0 {
        didSet {
            shapeLayer.strokeEnd = progress
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: min(bounds.width, bounds.height) / 2 - 5,
            startAngle: -.pi / 2,
            endAngle: .pi * 3 / 2,
            clockwise: true
        )

        shapeLayer.path = circlePath.cgPath
        shapeLayer.strokeColor = UIColor.systemBlue.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 6
        shapeLayer.strokeEnd = 0

        layer.addSublayer(shapeLayer)
    }

    func setProgress(_ value: CGFloat) {
        progress = min(max(0, value), 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        setup()
    }
}
