//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

extension UITableViewCell {
	/// A string that can be used as a reuse identifer for this cell, currently the name of the class.
	/// (This is for the most common use case when all cells of the same type are considered equal.)
	public static var defaultReuseIdentifier: String { return NSStringFromClass(self) }
}

extension UITableView {

	/**
		Dequeues a cell with the given identifier via `dequeueReusableCell(withIdentifier:)`
		or creates a new one if the latter returns `nil`.

		This implements the common "try to dequeue first or create it if unavailable" pattern, which allows to avoid
		registering cells in advance which in turn allows to avoid standard initializers.

		Example:

		```
		let stepCell = _view.tableView.dequeueReusableCell(StepCell.defaultReuseIdentifier) {
			StepCell()
		}
		```
	*/
	public func dequeueReusableCell<CellType: UITableViewCell>(
		_ identifier: String,
		creationBlock: (_ identifier: String) -> CellType
	) -> CellType {
		if let c = self.dequeueReusableCell(withIdentifier: identifier) as? CellType {
			return c
		} else {
			return creationBlock(identifier)
		}
	}
}

extension UICollectionViewCell {
	
	/// A string that can be used as a reuse identifer for this cell, currently the name of the class.
	/// (This is for the most common use case when all cells of the same type are considered equal.)
	public static var defaultReuseIdentifier: String { return NSStringFromClass(self) }
}

extension UICollectionView {
	
	/**
		Dequeues a cell with the given identifier via `dequeueReusableCell(withIdentifier:indexPath:)`
		or creates a new one if the latter returns `nil`.

		This implements the common "try to dequeue first or create it if unavailable" pattern, which allows to avoid
		registering cells in advance which in turn allows to avoid standard initializers.

		Example:

		```
		let stepCell = _view.collectionView.dequeueReusableCell(StepCell.defaultReuseIdentifier, indexPath: indexPath) {
			StepCell()
		}
		```
	*/
	public func dequeueReusableCell<CellType: UICollectionViewCell>(
		_ indentifier: String,
		indexPath: IndexPath,
		creationBlock: () -> CellType
	) -> CellType {
		if let c = self.dequeueReusableCell(withReuseIdentifier: indentifier, for: indexPath) as? CellType {
			return c
		} else {
			return creationBlock()
		}
	}
}

/// Shortcuts for on-the-fly attribute tweaking.
extension Dictionary where Key == NSAttributedString.Key, Value == Any {

	/// Same attributes but merging ones from the given dictionary overriding the existing ones.
	/// (Note that composite attributes such as paragraph style are not merged property by property.)
	public func withAttributes(_ attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
		var dictionary = self
		dictionary.merge(attributes) { $1 }
		return dictionary
	}

	/// Same attributes but with the value of `.paragraphStyle` attribute adjusted by your closure.
	/// (In case the original dictionary has no paragraph style attribute, then it's added.)
	public func withParagraphStyle(block: (inout NSMutableParagraphStyle) -> Void) -> [NSAttributedString.Key: Any] {

		var dictionary = self 

		var ps: NSMutableParagraphStyle = {
			if let existing = self[.paragraphStyle] as? NSParagraphStyle {
				return existing.mutableCopy() as! NSMutableParagraphStyle
			} else {
				return NSMutableParagraphStyle()
			}
		}()

		block(&ps)

		dictionary[.paragraphStyle] = ps

		return dictionary 
	}

	/// Same attributes but with paragraph style's alignment property changed to the specified value.
	/// (In case the original dictionary has no paragraph style attribute, then it's added.)
	public func withAlignment(_ alignment: NSTextAlignment) -> [NSAttributedString.Key: Any] {
		return withParagraphStyle { $0.alignment = alignment }
	}

	/// Same attributes but with the value of `.foregroundColor` set to the given value.
	public func withColor(_ color: UIColor) -> [NSAttributedString.Key: Any] {
		var dictionary = self
		dictionary[.foregroundColor] = color
		return dictionary
	}
}

extension UIEdgeInsets {

	/// Shorter initializer avoiding labels.
	public init(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) {
		self.init(top: top, left: left, bottom: bottom, right: right)
	}

	/// Insets with all the components increased by the given value.
	public func inset(by delta: CGFloat) -> UIEdgeInsets {
		return UIEdgeInsets(top: top + delta, left: left + delta, bottom: bottom + delta, right: right + delta)
	}

	/// Insets with all the components insets by the corresponding components of another insets object.
	///
	/// Note that overloading the '+' operator would make it hard to discover.
	public func inset(by insets: UIEdgeInsets) -> UIEdgeInsets {
		return UIEdgeInsets(
			top: top + insets.top,
			left: left + insets.left,
			bottom: bottom + insets.bottom,
			right: right + insets.right
		)
	}
}

// MARK: - This is for misc stuff that is hard to group initially now.
