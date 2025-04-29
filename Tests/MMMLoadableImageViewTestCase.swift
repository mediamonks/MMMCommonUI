//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@testable import MMMCommonUI
import MMMTestCase

class MMMLoadableImageViewTestCase: MMMTestCase {

	public override func setUp() {
		super.setUp()
		self.recordMode = false
	}

    private func stubImage(
    	size: CGSize,
    	backgroundColor: UIColor,
    	borderColor: UIColor,
    	borderWidth: CGFloat = 1
	) -> UIImage {

    	let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    	UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

    	let c = UIGraphicsGetCurrentContext()!

		let halfBorder = borderWidth / 2
    	c.addRect(bounds.insetBy(dx: halfBorder, dy: halfBorder))

		backgroundColor.setFill()
		borderColor.setStroke()
		c.setLineWidth(borderWidth)
		c.drawPath(using: .fillStroke)

    	let result = UIGraphicsGetImageFromCurrentImageContext()!
    	UIGraphicsEndImageContext()

    	return result
    }

    private lazy var landscapeImage = {
		return stubImage(
			size: CGSize(width: 40, height: 20),
			backgroundColor: MMMDebugColor(1),
			borderColor: MMMDebugColor(2)
		)
	}()

	private lazy var portraitImage = {
		return stubImage(
			size: CGSize(width: 20, height: 40),
			backgroundColor: MMMDebugColor(2),
			borderColor: MMMDebugColor(3)
		)
    }()

    public func testModes() {

    	// In this test I am only interested in the correct handling of fit/fill modes,
    	// and a placeholder should be enough for that.

    	self.varyParameters([
    		"placeholder": [
				"landscape": landscapeImage,
				"portrait": portraitImage
    		],
    		"mode": [
    			"fit": .fit,
    			"fill": .fill
    		] as [String: MMMLoadableImageView.Mode]
    	]) { (identifier, values) in

			let view = MMMLoadableImageView(
				placeholderImage: values["placeholder"] as! UIImage?,
				mode: values["mode"] as! MMMLoadableImageView.Mode
			)

			// Want it to stay square to test the modes.
			NSLayoutConstraint.activate(NSLayoutConstraint(
				item: view, attribute: .width,
				relatedBy: .equal,
				toItem: view, attribute: .height,
				multiplier: 1, constant: 0
			))

			self.verify(
				view: view,
				fits: [
					// Let's see that it can stretch if the image is smaller than the space we have.
					.size(width: 60, height: 60)
				],
				identifier: identifier,
				backgroundColor: MMMDebugColor(0)
			)
		}
    }

    public func testBasics() {

    	// This is where I want to check if the "loadable" part of it is working OK.

		let image = MMMTestLoadableImage()
		XCTAssert(image.loadableState == .idle)
		XCTAssert(!image.hasObservers)

		// Want to make sure the view is deallocated and removes its observer.
		autoreleasepool {

			let view = MMMLoadableImageView(
				placeholderImage: stubImage(
					size: CGSize(width: 40, height: 40),
					backgroundColor: MMMDebugColor(0),
					borderColor: MMMDebugColor(0)
				),
				mode: .fill
			)

			NSLayoutConstraint.activate(NSLayoutConstraint(
				item: view, attribute: .width,
				relatedBy: .lessThanOrEqual,
				toItem: nil, attribute: .notAnAttribute,
				multiplier: 1, constant: 20
			))
			NSLayoutConstraint.activate(NSLayoutConstraint(
				item: view, attribute: .height,
				relatedBy: .lessThanOrEqual,
				toItem: nil, attribute: .notAnAttribute,
				multiplier: 1, constant: 20
			))

			// No image is set yet, should see only the placeholder.
			self.verify(view: view, fit: .natural, identifier: "000_initial")

			view.image = image
			XCTAssert(image.loadableState == .syncing, "Should begin refreshing the image")
			XCTAssert(image.hasObservers, "Should have started observing it")

			// Currently should display a placeholder while syncing. Might be a shimmer at some point.
			self.verify(view: view, fit: .natural, identifier: "001_syncing")

			// Should continue displaying a placeholder after a failure.
			image.setDidFailToSyncWithError(nil)
			self.verify(view: view, fit: .natural, identifier: "002_failed")

			// Should display our image once we got it.
			image.setDidSyncSuccessfullyWith(landscapeImage)
			self.verify(view: view, fit: .natural, identifier: "003_loaded")

			// Refreshing again extrernally should keep the loaded image.
			image.setSyncing()
			self.verify(view: view, fit: .natural, identifier: "004_syncing_again")

			// And failing it again should keep the existing one.
			image.setDidFailToSyncWithError(nil)
			self.verify(view: view, fit: .natural, identifier: "005_failed_again")
		}

		XCTAssert(!image.hasObservers)
    }
}
