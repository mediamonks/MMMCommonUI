//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2025 Monks. All rights reserved.
//

import MMMCommonUI
import MMMTestCase

public final class MMMTextLayoutTestCase: MMMTestCase {

	public override func setUp() {
		super.setUp()
		self.recordMode = false
	}

	/// A stub view with a label and extra alignment rect to demo baseline alignment.
	private class TestView: NonStoryboardableView {

		private let label: UILabel = {
			let label = UILabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			return label
		}()

		private let insets: UIEdgeInsets

		public init(text: String, fontSize: CGFloat, insets: UIEdgeInsets) {

			self.insets = insets

			super.init()

			layer.cornerRadius = 3
			layer.masksToBounds = true
			backgroundColor = MMMDebugColor(0).withAlphaComponent(0.5)

			label.textColor = MMMDebugColor(1)
			label.font = .monospacedSystemFont(ofSize: fontSize, weight: .bold)
			label.text = text
			label.layer.borderColor = MMMDebugColor(2).cgColor
			label.layer.borderWidth = 1
			label.layer.cornerRadius = 2
			addSubview(label)

			mmm_addConstraintsAligningView(label, horizontally: .fill, vertically: .fill)
		}

		public override var alignmentRectInsets: UIEdgeInsets { insets }
		public override var forLastBaselineLayout: UIView { label }
	}

	private func threeViews() -> [UIView] {
		[
			TestView(text: "foo", fontSize: 8, insets: .init(10, 5, 5, 0)),
			TestView(text: "bar", fontSize: 24, insets: .init(5, 0, 10, 5)),
			{
				let v = MMMImageView(image: .mmm_rectangle(size: .init(width: 10, height: 32), color: MMMDebugColor(4)))
				v.layer.shadowOffset = .init(2, 2)
				v.layer.shadowColor = .init(gray: 0, alpha: 1)
				v.layer.shadowOpacity = 0.3
				return v
			}()
		]
	}

	private func text1(skipping: Set<Int> = []) -> NSAttributedString {

		func placeholder(_ index: Int) -> NSAttributedString {
			if !skipping.contains(index) {
				MMMTextLayout.placeholderForView(index)
			} else {
				.init(string: "[skip]", attributes: [ .font: UIFont.italicSystemFont(ofSize: 14), .foregroundColor: MMMDebugColor(0) ])
			}
		}

		return .init(
			format: "A %@ is a view and a %@ is %@; enjoy little %@ as %@.",
			attributes: [
				.font: UIFont.systemFont(ofSize: 14),
				.foregroundColor: MMMDebugColor(0)
			],
			args: [
				placeholder(1),
				placeholder(0),
				.init(string: "too", attributes: [ .font: UIFont.boldSystemFont(ofSize: 20), .foregroundColor: MMMDebugColor(0) ]),
				placeholder(2),
				.init(
					string: "MMMImageView",
					attributes: [ .font: UIFont.italicSystemFont(ofSize: 14), .foregroundColor: MMMDebugColor(0) ]
				)
			]
		)
	}

	public func testBasics() {

		let layout = MMMTextLayout()
		layout.setSubviews(threeViews())
		layout.text = text1()

		for width in [0, 100, 200, 300] {
			verify(view: layout, fit: .size(width: CGFloat(width), height: 0), backgroundColor: .white)
		}

		// Let's see how it looks when there is not enough height.
		for height in [80, 40] {
			verify(view: layout, fit: .size(width: CGFloat(100), height: CGFloat(height)), backgroundColor: .white)
		}
	}

	public func testEmpty() {

		let layout1 = MMMTextLayout()
		verify(view: layout1, fit: .size(width: CGFloat(100), height: 0), identifier: "empty", backgroundColor: .white)

		layout1.setSubviews(threeViews())
		// Reusing the identifier, because the snapshot should be the same.
		verify(view: layout1, fit: .size(width: CGFloat(100), height: 0), identifier: "empty", backgroundColor: .white)

		layout1.text = text1()
		verify(view: layout1, fit: .size(width: CGFloat(100), height: 0), identifier: "views-or-text-first", backgroundColor: .white)

		let layout2 = MMMTextLayout()
		layout2.text = text1()
		verify(view: layout2, fit: .size(width: CGFloat(100), height: 0), identifier: "no-views", backgroundColor: .white)

		layout2.setSubviews(threeViews())
		// Reusing the identifier, because the snapshot should be the same.
		verify(view: layout2, fit: .size(width: CGFloat(100), height: 0), identifier: "views-or-text-first", backgroundColor: .white)
	}

	public func testHidesUnreferenced() {

		// When a view is not mentioned in the template, then it should be hidden.

		let layout = MMMTextLayout()
		layout.setSubviews(threeViews())
		layout.text = text1(skipping: [1])
		verify(view: layout, fit: .size(width: CGFloat(100), height: 0), identifier: "skipping-1", backgroundColor: .white)

		layout.text = text1(skipping: [0, 2])
		verify(view: layout, fit: .size(width: CGFloat(100), height: 0), identifier: "skipping-0-2", backgroundColor: .white)
	}
}
