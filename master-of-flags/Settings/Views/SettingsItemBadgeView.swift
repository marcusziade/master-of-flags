import Foundation
import SnapKit
import SwiftUI
import UIKit

final class SettingsItemBadgeView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        addAndConstrainSubview(backgroundView) {
            $0.edges.equalToSuperview()
        }

        addAndConstrainSubview(itemImageView) {
            $0.edges.equalToSuperview().inset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with image: UIImage, color: UIColor) {
        backgroundView.backgroundColor = color
        itemImageView.image = image
    }

    // MARK: - Private

    private let backgroundView = UIView()
        .configure {
            $0.layer.cornerRadius = 6
            $0.backgroundColor = .systemPurple
        }

    private let itemImageView = UIImageView()
        .configure {
            $0.heightAnchor.constraint(equalToConstant: 25).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 25).isActive = true
            $0.contentMode = .scaleAspectFit
            $0.tintColor = .white
            $0.image = UIImage(systemName: "gamecontroller")
        }
}

struct ItemImageView_Preview: PreviewProvider {
    static var previews: some View = Preview(for: SettingsItemBadgeView())
        .previewLayout(.sizeThatFits)
}
