//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2021 MediaMonks. All rights reserved.
//

/// Support for simple grid layouts.
public final class MMMGridContainer: MMMVerticalStackContainer {

	private let columnSpacing: CGFloat
	private let rowAlignment: MMMLayoutVerticalAlignment
	private let equalColumnWidthPriority: UILayoutPriority
	private let equalRowHeightPriority: UILayoutPriority

	/// - Parameters:
	///
	///   - horizontalSpacing: Horizontal space between each pair of consecutive views in each row.
	///
	///     `0` by default.
	///
	///   - verticalSpacing: Vertical space between each pair of consecutive rows.
	///
	///     `0` by default.
	///
	///   - rowAlignment: How to vertically align views within each row.
	///
	///     Default is `.fill`, i.e. top/bottom edges of views within the same row are going to be aligned.
	///
	///   - equalColumnWidthPriority: Priority to constrain views within each row to have the same width with.
	///
	///     `.defaultHigh + 1` by default, so, for example, labels will be compressed to achieve same width goal.
	///
	///   - equalRowHeightPriority: Priority to constrain all rows to have the same height with.
	///
	///     `.defaultLow - 1` by default, so, for example, labels won't be stretched to achieve same height goal.
	///
	///   - insets: Insets to add around the contents of the container.
	///
	///   	`.zero` by default.
	///
	///   - alignment: How to horizontally align all the rows of the grid.
	///
	///     Default is `fill`, i.e. all rows are pinned to the sides of the container.
	public init(
		horizontalSpacing: CGFloat = 0,
		verticalSpacing: CGFloat = 0,
		rowAlignment: MMMLayoutVerticalAlignment = .fill,
		equalColumnWidthPriority: UILayoutPriority = .defaultHigh + 1,
		equalRowHeightPriority: UILayoutPriority = .defaultLow - 1,
		insets: UIEdgeInsets = .zero,
		alignment: MMMLayoutHorizontalAlignment = .fill
	) {
		self.columnSpacing = horizontalSpacing
		self.rowAlignment = rowAlignment
		self.equalColumnWidthPriority = equalColumnWidthPriority
		self.equalRowHeightPriority = equalRowHeightPriority

		super.init(insets: insets, alignment: alignment, spacing: verticalSpacing)
	}

	/// Sets the views to align into a grid having `numberOfColumns` columns.
	///
	/// Note that the last row might be aligned on its own if the number of views is not a multiple
	/// of `numberOfColumns`; see `setSubviews(_:)`.
	public func setSubviews(_ views: [UIView], numberOfColumns: Int) {
		var rows: [[UIView]] = []
		for i in stride(from: views.startIndex, to: views.endIndex, by: numberOfColumns) {
			let slice = views[i..<(min(i + numberOfColumns, views.endIndex))]
			rows.append(Array<UIView>(slice))
		}
		setSubviews(rows)
	}

	/// Sets the views to align into a grid. All views set previously are removed from the container first.
	///
	/// Note that rows can have different numbers of views. The same-width constraints will be set only between
	/// the rows of the same size, leading to different alignment groups, which is a desired effect sometimes,
	/// e.g.:
	/// ```
	/// ┌────┐┌────┐┌────┐
	/// ├────┴┴─┬┬─┴┴────┤
	/// ├───────┴┴───────┤
	/// ├────┬┬────┬┬────┤
	/// ├────┴┴─┬┬─┴┴────┤
	/// ├───────┤├───────┤
	/// └───────┘└───────┘
	/// ```
	public func setSubviews(_ rows: [[UIView]]) {

		let rowStacks = rows.map { rowViews -> MMMHorizontalStackContainer in
			let rowStack = MMMHorizontalStackContainer(insets: .zero, alignment: rowAlignment, spacing: columnSpacing)
			rowStack.setSubviews(rowViews)
			for i in stride(from: rowViews.startIndex, to: rowViews.endIndex - 1, by: 1) {
				NSLayoutConstraint.activate(NSLayoutConstraint(
					item: rowViews[i], attribute: .width,
					relatedBy: .equal,
					toItem: rowViews[i + 1], attribute: .width,
					multiplier: 1, constant: 0,
					priority: equalColumnWidthPriority,
					identifier: "MMM-EqualColumnWidth"
				))
			}
			return rowStack
		}

		super.setSubviews(rowStacks)

		// Let's apply same row height constraint.
		for i in stride(from: rowStacks.startIndex, to: rowStacks.endIndex - 1, by: 1) {
			NSLayoutConstraint.activate(NSLayoutConstraint(
				item: rowStacks[i], attribute: .height,
				relatedBy: .equal,
				toItem: rowStacks[i + 1], attribute: .height,
				multiplier: 1, constant: 0,
				priority: equalRowHeightPriority,
				identifier: "MMM-EqualRowHeight"
			))
		}

		// Now we want to make cells of equal width but only between the rows with the same number of columns.
		var processed = Set<Int>.init()
		for (rowIndex, row) in rows.enumerated() {

			let colCount = row.count

			// Skip the rows processed before.
			if processed.contains(colCount) { continue }

			// Look for all the rows with the same number of columns below and align to them.
			for nextRow in rows[(rowIndex + 1)...] where nextRow.count == colCount {
				for (i, v2) in row.enumerated() {
					let v1 = nextRow[i]
					NSLayoutConstraint.activate(NSLayoutConstraint(
						item: v1, attribute: .width,
						relatedBy: .equal,
						toItem: v2, attribute: .width,
						multiplier: 1, constant: 0,
						// This constraint is what makes it a grid, so not configurable priority.
						priority: .required,
						identifier: "MMM-Column\(i)Of\(colCount)ColumnRows"
					))
				}
			}

			// OK, the rows with this number of columns are processed.
			processed.insert(colCount)
		}
	}
}
