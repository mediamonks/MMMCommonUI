//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

import UIKit

#if SWIFT_PACKAGE
import MMMCommonUIObjC
#endif

/// Swift additions for `MMMStylesheet`.
extension MMMStylesheet {

	/// More compact version of `insets(fromRelativeInsets:)` which was taking more space to write in Swift
	/// due to the labels needed in the initializer of `UIEdgeInsets`.
	public func insetsFromRelativeInsets(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) -> UIEdgeInsets {
		return self.insets(fromRelativeInsets: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
	}
}
