//
// Starbucks App.
// Copyright (c) 2024 MediaMonks. All rights reserved.
// 

import UIKit

/// A container arranging subviews as words on a page.
///
/// Note that calling ``systemLayoutSizeFitting()`` won't work properly here as our height depends on width.
///
/// Things that could be improved:
/// - recycle horizontal (row) stack views;
/// - use UILayoutGuide's directly instead of stack views.
public class MMMFlowLayoutContainer: NonStoryboardableView {

	private let insets: UIEdgeInsets
	private let horizontalSpacing: CGFloat
	private let verticalAlignment: MMMLayoutVerticalAlignment
	private let horizontalFittingPriority: UILayoutPriority
	private let verticalStack: MMMVerticalStackContainer

	public init(
		horizontalSpacing: CGFloat,
		verticalSpacing: CGFloat,
		insets: UIEdgeInsets = .zero,
		horizontalAlignment: MMMLayoutHorizontalAlignment = .left,
		verticalAlignment: MMMLayoutVerticalAlignment = .center,
		horizontalSizingPriority: UILayoutPriority = .defaultLow - 1
	) {
		self.insets = insets
		self.verticalStack = .init(insets: insets, alignment: horizontalAlignment, spacing: verticalSpacing)
		self.horizontalSpacing = horizontalSpacing
		self.verticalAlignment = verticalAlignment
		self.horizontalFittingPriority = horizontalSizingPriority

		super.init()

		addSubview(verticalStack)

		mmm_addConstraintsAligningView(verticalStack, horizontally: .fill, vertically: .fill)
	}

	private var arrangedSubviews: [UIView] = []

	public func setSubviews(_ subviews: [UIView]) {
		guard self.arrangedSubviews != subviews else {
			return
		}
		arrangedSubviews.forEach { $0.removeFromSuperview() }
		self.arrangedSubviews = subviews
		arrangedSubviews.forEach { addSubview($0) }
		setNeedsUpdateConstraints()
	}

	private var lastConstrainedWidth: CGFloat = 0

	public override func updateConstraints() {

		super.updateConstraints()

		lastConstrainedWidth = bounds.width

		let totalWidth = bounds.inset(by: insets).width
		guard totalWidth > 0 else {
			verticalStack.setSubviews([])
			return
		}

		var rows: [MMMHorizontalStackContainer] = []
		var currentRow: [UIView] = []
		var remainingWidth: CGFloat = 0

		func flush() {
			remainingWidth = totalWidth
			guard !currentRow.isEmpty else {
				return
			}
			let rowStack = MMMHorizontalStackContainer(insets: .zero, alignment: verticalAlignment, spacing: horizontalSpacing)
			rowStack.setSubviews(currentRow)
			rows.append(rowStack)
			currentRow.removeAll()
		}

		func measure(_ subview: UIView) -> CGFloat {
			ceil(subview.systemLayoutSizeFitting(
				.init(remainingWidth, 0),
				withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: .fittingSizeLevel
			).width)
		}

		flush()

		for subview in arrangedSubviews {
			var w = measure(subview)
			if w > remainingWidth {
				flush()
				w = measure(subview)
			}
			currentRow.append(subview)
			remainingWidth -= w + horizontalSpacing
			if remainingWidth <= 0 {
				flush()
			}
		}
		flush()

		verticalStack.setSubviews(rows)
	}

	public override func layoutSubviews() {
		if lastConstrainedWidth != bounds.width {
			setNeedsUpdateConstraints()
			updateConstraintsIfNeeded()
		}
		super.layoutSubviews()
	}
}
