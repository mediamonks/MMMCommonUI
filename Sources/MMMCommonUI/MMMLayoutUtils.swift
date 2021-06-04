//
// MMMTemple.
// Copyright (C) 2019 MediaMonks. All rights reserved.
//

import UIKit

#if SWIFT_PACKAGE
import MMMCommonUIObjC
#endif

extension MMMLayoutUtils {

	/// Shortcut for `MMMLayoutUtils.centerMultiplier(forRatio: MMMLayoutUtils.inverseGolden)`.
	public static var inverseGoldenMultiplier: CGFloat {
		return centerMultiplier(forRatio: inverseGolden)
	}

	/// Shortcut for `MMMLayoutUtils.centerMultiplier(forRatio: MMMLayoutUtils.golden)`.
	public static var goldenMultiplier: CGFloat {
		return centerMultiplier(forRatio: golden)
	}
}

extension UIView {

	/**
	Adds constraints centering the given `view` within the receiver, ensuring same `minPadding` on the sides
	and optionally limiting the width to `maxWidth`.

	This is a layout pattern commonly used with text-like content:
	 - the given view is centered within the receiver,
	 - certain minimum padding is ensured on the sides,
	 - the width of the view is limited to the given one so, let say the text does not become too wide on iPad
	   (if `maxWidth` is `0` or negative, then it's ignored).
	 */
	open func mmm_addConstraintsHorizontallyCentering(_ view: UIView, minPadding: CGFloat = 0, maxWidth: CGFloat = 0) {
		self.__mmm_addConstraintsHorizontallyCentering(view, minPadding: minPadding, maxWidth: maxWidth)
	}

	/// Similar to `mmm_addConstraints(horizontallyCenteringView:minPadding:maxWidth:)` but returns constraints
	/// without adding them.
	open func mmm_constraintsHorizontallyCentering(_ view: UIView, minPadding: CGFloat, maxWidth: CGFloat) -> [NSLayoutConstraint] {
		return self.__mmm_constraintsHorizontallyCentering(view, minPadding: minPadding, maxWidth: maxWidth)
	}
}
