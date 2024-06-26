import Combine
import Foundation
import Lottie
import SafariServices
import SnapKit
import SwiftUI
import UIKit

final class TipJarViewController: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.addSublayer(gradientLayer)

        view.addAndConstrainSubview(collectionView) {
            $0.edges.equalToSuperview()
        }

        view.addAndConstrainSubview(loadingView) {
            $0.edges.equalToSuperview()
        }

        view.addAndConstrainSubview(animationView) {
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
        }

        model.fetchProducts()
        startListeningForStoreKit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        openParentalGateIfNeeded()
        // Force starts the animations inside the cells
        collectionView.reloadData()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        gradientLayer.frame = view.bounds
    }

    // MARK: - Private

    private let model = TipJarViewModel()

    private var cancellables = Set<AnyCancellable>()

    private let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom

    private var isLoading: Bool = true {
        didSet {
            if isLoading {
                loadingView.start()
            } else {
                loadingView.stop()
                collectionView.reloadData()
            }
        }
    }

    private lazy var gradientLayer = CAGradientLayer()
        .configure {
            $0.frame = view.bounds
            $0.colors = [UIColor.red.cgColor, UIColor.orange.cgColor, UIColor.yellow.cgColor]
            $0.startPoint = CGPoint.zero
            $0.endPoint = CGPoint(x: 0.5, y: 1.5)
        }

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: viewLayout)
        .configure {
            $0.dataSource = self
            $0.delegate = self
            $0.backgroundColor = .clear

            $0.registerCell(TipJarProductCell.self)
            $0.registerSupplementaryView(TipJarLegalFooterView.self, kind: .layoutFooter)
        }

    private var viewLayout: UICollectionViewLayout {
        let sectionProvider = {
            [unowned self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            let sectionLayout: NSCollectionLayoutSection

            guard let section = TipJarSection(rawValue: sectionIndex) else { return nil }

            switch section {
            case .tips:
                sectionLayout = tipsLayout
            }

            let footerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1), heightDimension: .estimated(160))
            let footer = NSCollectionLayoutBoundarySupplementaryItem.create(
                layoutSize: footerSize,
                elementKind: .layoutFooter,
                alignment: .bottom
            )

            sectionLayout.boundarySupplementaryItems = [footer]

            return sectionLayout
        }

        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }

    private var tipsLayout: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: .zero, leading: 4, bottom: .zero, trailing: 4)

        var size: (width: Double, height: Double)
        switch deviceIdiom {
        case .pad: size = (1, 0.3)
        case .phone: size = (1, 0.25)
        case .tv: size = (0.3, 0.25)
        default: size = (1, 0.25)
        }

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(size.width),
            heightDimension: .fractionalHeight(size.height)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        group.edgeSpacing = NSCollectionLayoutEdgeSpacing(
            leading: .fixed(0),
            top: .fixed(4),
            trailing: .fixed(0),
            bottom: .fixed(4)
        )

        let section = NSCollectionLayoutSection(group: group)

        return section
    }

    private var loadingView = LoadingView(state: .loading)

    private let animationView = AnimationView()
        .configure {
            $0.contentMode = .scaleAspectFit
            $0.loopMode = .playOnce
            $0.backgroundColor = .clear
            $0.alpha = 0
        }

    private func showPurchaseSuccesfulAnimation(for product: TipJarProduct) {
        UIView.animate(withDuration: 0.3) { [self] in
            animationView.alpha = 1
        }

        animationView.animation = Animation.named(product.animation)

        animationView.play { [weak self] _ in
            UIView.animate(withDuration: 0.3) {
                self?.animationView.alpha = 0
            }
        }
    }

    private func startListeningForStoreKit() {
        model.onTransactionStateChanged
            .sink { [unowned self] transationsState in
                switch transationsState {
                case .purchasing:
                    loadingView.state = .purchasing
                case .purchased:
                    loadingView.state = .purchased
                    showPurchaseSuccesfulAnimation(for: model.selectedProduct!)
                case .failed:
                    loadingView.state = .failed
                case .restored:
                    print("restored")
                case .deferred:
                    print("deferred")
                case .error:
                    loadingView.state = .error
                }

                isLoading = transationsState == .purchasing
            }
            .store(in: &cancellables)

        model.onProductsLoaded
            .sink { [unowned self] in
                DispatchQueue.main.async { [self] in
                    isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    private func openParentalGateIfNeeded() {
        if !Settings.parentalGateUnlocked {
            var parentalGate = ParentalGateView()

            parentalGate.onCancel = { [unowned self] in
                HapticEngine.result.notificationOccurred(.error)
                dismiss(animated: true)
                navigationController?.popToRootViewController(animated: true)
            }

            parentalGate.onClose = { [unowned self] in
                Settings.parentalGateUnlocked = true
                dismiss(animated: true)
                HapticEngine.result.notificationOccurred(.success)
            }

            let viewController = UIHostingController(rootView: parentalGate)
            viewController.isModalInPresentation = true
            present(viewController, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension TipJarViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        TipJarSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = TipJarSection(rawValue: section) else { return 0 }
        switch section {
        case .tips:
            return model.products.value.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let section = TipJarSection(rawValue: indexPath.section) else { return UICollectionViewCell() }
        switch section {
        case .tips:
            return collectionView.dequeueCell(TipJarProductCell.self, forIndexPath: indexPath)
                .configure {
                    $0.configure(with: model.products.value[indexPath.item])
                }
        }
    }
}

extension TipJarViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = TipJarSection(rawValue: indexPath.section) else { return }
        switch section {
        case .tips:
            model.productSelected(for: indexPath)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        return
            collectionView.dequeueSupplementaryView(
                TipJarLegalFooterView.self,
                kind: .layoutFooter,
                indexPath: indexPath
            )
            .configure {
                $0.onPolicyPressed = { [unowned self] in
                    let safariConfig = SFSafariViewController.Configuration()
                    safariConfig.entersReaderIfAvailable = true
                    present(
                        SFSafariViewController(
                            url: URL(string: "https://pages.flycricket.io/know-your-flags/privacy.html")!,
                            configuration: safariConfig
                        ),
                        animated: true
                    )
                }

                $0.onTermsPressed = { [unowned self] in
                    present(UIHostingController(rootView: TermsView()), animated: true)
                }
            }
    }
}

struct TipJarViewController_Preview: PreviewProvider {

    static var previews: some View = Preview(for: TipJarViewController())
}
