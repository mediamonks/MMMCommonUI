//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

import UIKit

/// Called from those initializers required by `NSCoding` that we often don't support.
///
/// Example:
/// ```
///	required init?(coder aDecoder: NSCoder) { storyboardsNotSupported(by: type(of: self)) }
/// ```
public func storyboardsNotSupported(by type: AnyClass, file: StaticString = #file, line: UInt = #line) -> Never {
	preconditionFailure(
		"\(String(reflecting: type)) does not support decoding from storyboards/NIBs", file: file, line: line
	)
}

/// A base for views that do not support NIBs/storyboards, so there is no need in defining
/// `required init?(coder:)` initializer. It also declares Auto Layout support and resets
/// `translatesAutoresizingMaskIntoConstraints`.
open class NonStoryboardableView: UIView {

    public init() {
		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false
    }

	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) { storyboardsNotSupported(by: type(of: self)) }

	// Sometimes a custom view based on this class does not define internal constraints and thus does not work
	// properly if somebody just asks about its preferred size (something happening in MMMTestCase), so we have to hint
	// the system that Auto Layout should be used.
	// (Using `class` instead of `static` to work around an invalid warning in Swift 4.2.)
	@objc open override class var requiresConstraintBasedLayout: Bool {
		return true
	}
}

/// A base for controls that do not support NIBs/storyboards, so there is no need in defining
/// `required init?(coder:)` initializer.
open class NonStoryboardableControl: UIControl {

    public init() {
		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false
    }

	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) { storyboardsNotSupported(by: type(of: self)) }

	@objc open override class var requiresConstraintBasedLayout: Bool {
		return true
	}
}

/// A base for table view cells that do not support NIBs/storyboards, so there is no need in defining
/// `required init?(coder:)` initializer.
open class NonStoryboardableTableViewCell: UITableViewCell {

	public init(reuseIdentifier: String?) {
		super.init(style: .default, reuseIdentifier: reuseIdentifier)
	}

	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) { storyboardsNotSupported(by: type(of: self)) }
}

/// A base for collection view cells that do not support NIBs/storyboards, so there is no need in defining
/// `required init?(coder:)` initializer.
open class NonStoryboardableCollectionViewCell: UICollectionViewCell {

    public override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) { storyboardsNotSupported(by: type(of: self)) }
}

/// A base for view controllers that do not support NIBs/storyboards, so there is no need in defining
/// `required init?(coder:)` initializer.
open class NonStoryboardableViewController: UIViewController {

    public init() {
		super.init(nibName: nil, bundle: nil)
    }

	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) { storyboardsNotSupported(by: type(of: self)) }
}
