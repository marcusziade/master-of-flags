import UIKit

// MARK: - Child Viewcontroller install methods

extension UIViewController {

    func install(_ child: UIViewController, to view: UIView, with constraints: [NSLayoutConstraint]) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate(constraints)
        child.didMove(toParent: self)
    }

    func unInstall(_ child: UIViewController, with constraints: [NSLayoutConstraint]) {
        child.willMove(toParent: nil)
        child.view.removeConstraints(constraints)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
}
