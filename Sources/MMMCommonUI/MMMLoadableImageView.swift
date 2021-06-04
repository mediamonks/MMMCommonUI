//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

import UIKit

#if SWIFT_PACKAGE
import MMMCommonUIObjC
import MMMLoadable
#endif

/// An image view that is able to work with loadable images directly.
public final class MMMLoadableImageView: NonStoryboardableView {

	/// Scaling mode that should be used in case external constraints applied to this view do not allow
	/// it to have its natural size.
	///
	/// Note that there is no need in supporting all values of `UIView.ContentMode`.
	/// It makes no sense to not scale images loaded from somewhere or to scale them disproportionally.
	public enum Mode {
		case fill
		case fit
	}

	// Not inheriting from UIImageView, so it's easier to start clipping it at some point, add non-trivial background,
	// render decoration or animate loading state.
	// Using `MMMImageView` to solve troubles with alignment rects and take care of proportion constraints.
	private let imageView = MMMImageView()

	/// A view that can be used by outside views to align decoration views (e.g. shadows) with the bounds
	/// of the actual image. Use this only for constraints, don't change borders, background, etc.
	///
	/// Note that in case of the `.fill` mode the bounds of this view might reside outside of the receiver's bounds.
	public var alignmentView: UIView { imageView }

	// No reason to open this for changes at any time.
	private let placeholderImage: UIImage?

	private var imageObserver: MMMLoadableObserver?

	/// A loadable image this image view should display and track. Just set and forget.
	/// (Well, think of the max size you would like this image view to have and set the corresponding constraints.)
	public var image: MMMLoadableImage? {
		didSet {
			guard image !== oldValue else {
				return
			}
			if let loadableImage = image {
				imageObserver = MMMLoadableObserver(loadable: loadableImage) { [weak self] _ in
					self?.update(animated: true)
				}
			} else {
				imageObserver = nil
			}
			image?.syncIfNeeded()
			update(animated: false)
		}
	}

	// MARK: Init

	// TODO: visually distinguish between 'loading' and 'failed to load' states, e.g. by using two placeholders or possibly using "shimmer"-kind animation.
	// TODO: this is where effects like shadows and corners can be added as well.
	public init(placeholderImage: UIImage? = nil, mode: Mode = .fit) {

		self.placeholderImage = placeholderImage

		super.init()

		self.clipsToBounds = (mode == .fill)

		addSubview(imageView)

		do {

			let views = [ "imageView": imageView ]

			switch mode {
			case .fill:
				NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
					withVisualFormat: "H:|-(<=0,0@751)-[imageView]-(<=0,0@751)-|",
					metrics: nil, views: views
				))
				NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
					withVisualFormat: "V:|-(<=0,0@751)-[imageView]-(<=0,0@751)-|",
					metrics: nil, views: views
				))
			case .fit:
				// As always, using 749, so we pin only if that's possible without deforming the image view.
				NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
					withVisualFormat: "H:|-(>=0,0@749)-[imageView]-(>=0,0@749)-|",
					metrics: nil, views: views
				))
				NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
					withVisualFormat: "V:|-(>=0,0@749)-[imageView]-(>=0,0@749)-|",
					metrics: nil, views: views
				))
			}

			// Regardless of the mode we need to make sure the image is centered.

			NSLayoutConstraint.activate(NSLayoutConstraint(
				item: imageView, attribute: .centerX,
				relatedBy: .equal,
				toItem: self, attribute: .centerX,
				multiplier: 1, constant: 0,
				priority: .defaultHigh - 2
			))
			NSLayoutConstraint.activate(NSLayoutConstraint(
				item: imageView, attribute: .centerY,
				relatedBy: .equal,
				toItem: self, attribute: .centerY,
				multiplier: 1, constant: 0,
				priority: .defaultHigh - 2
			))
		}

		update(animated: false)
	}

	private func update(animated: Bool) {

		guard let loadableImage = image else {
			imageView.image = placeholderImage
			return
		}

		if loadableImage.isContentsAvailable {
			updateImage(with: loadableImage.image, animated: animated)
		} else {
			assert(loadableImage.loadableState == .syncing || loadableImage.loadableState == .didFailToSync)
			// TODO: currently we don't distinguish between loading and failed here, but would be better to so.
			updateImage(with: placeholderImage)
		}
	}
	
	private func updateImage(with image: UIImage?, animated: Bool = false) {
		guard animated else {
			imageView.image = image
			return
		}
		UIView.transition(
			with: imageView,
			duration: 0.25,
			options: [.beginFromCurrentState, .transitionCrossDissolve],
			animations: {
				self.imageView.image = image
			}
		)
	}
}
