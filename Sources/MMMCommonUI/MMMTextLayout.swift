//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2026 Monks. All rights reserved.
//

/// A view that allows mixing attributed text with custom views, something that is handy when you want to use a custom
/// icon in your text, a special link, or just decorate a word in a way that is not supported by CoreText directly.
///
/// How it works:
/// - You set subviews that should participate in the layout via ``setSubviews(_:)``.
/// - You set ``text`` where you are referring to those subviews by index adding ``ViewIndexAttribute`` attribute
///   on placeholder characters. (See ``placeholderForView(_:)`` helper.)
/// - Sizes and baselines of the referenced subviews are determined using Auto Layout. Unreferenced subviews are hidden.
/// - The ``text`` is rendered via CoreText with space reserved for the subviews in the corresponding locations.
/// - The subviews are positioned with Auto Layout constraints against the leftmost points of their baselines.
///
/// Note that to support SwiftUI wrappers the old ``sizeThatFits(_:)`` API is supported here to allow estimating
/// the height of the view given proposed width.
public class MMMTextLayout: NonStoryboardableView {

	private let shouldTrimLeading: Bool

	/// - Parameter shouldTrimLeading: when `true` (default), then the space above the ascent of the first line
	///   is excluded from the layout. This is handy when paragraph style uses `lineHeightMultiple` but you don't want
	///   increased padding before the first line.
	public init(shouldTrimLeading: Bool = true) {
		self.shouldTrimLeading = shouldTrimLeading
		super.init()
		self.isOpaque = false
		self.contentMode = .redraw
	}

	private var managedViews: [ManagedView] = []

	private struct ManagedView {
		var view: UIView
		var boundsGuide: UILayoutGuide
		var ascentGuide: UILayoutGuide
		var leftConstraint: NSLayoutConstraint
		var baselineConstraint: NSLayoutConstraint
	}

	/// The views to layout.
	///
	/// Only the subviews added via this method can be referenced from ``text`` and participate in the layout.
	/// The receiver controls both the position and the visibility of these views: the ones that are not referenced
	/// from ``text`` (the part of it that is actually visible) are going to be automatically hidden.
	public func setSubviews(_ views: [UIView]) {
		for r in managedViews {
			removeLayoutGuide(r.ascentGuide)
			removeLayoutGuide(r.boundsGuide)
			r.view.removeFromSuperview()
		}
		managedViews = views.map { view in
			.init(
				view: view,
				boundsGuide: .init(),
				ascentGuide: .init(),
				// The constants of both of these are updated to position the view.
				leftConstraint: view.leftAnchor.constraint(equalTo: self.leftAnchor),
				baselineConstraint: view.firstBaselineAnchor.constraint(equalTo: self.topAnchor)
			)
		}
		for r in managedViews {
			addSubview(r.view)
			addLayoutGuide(r.boundsGuide)
			addLayoutGuide(r.ascentGuide)
		}
		for r in managedViews {
			NSLayoutConstraint.activate([
				r.leftConstraint,
				r.baselineConstraint,
				// One guide will give us width/height of the view without the need to size it separately.
				r.boundsGuide.widthAnchor.constraint(equalTo: r.view.widthAnchor, multiplier: 1),
				r.boundsGuide.heightAnchor.constraint(equalTo: r.view.heightAnchor, multiplier: 1),
				// And another one is needed for the baseline info, i.e. ascent/descent.
				r.ascentGuide.topAnchor.constraint(equalTo: r.view.topAnchor),
				r.ascentGuide.bottomAnchor.constraint(equalTo: r.view.firstBaselineAnchor)
			])
		}
		resetTextFrame()
	}

	/// The attributed text to render.
	///
	/// The subviews set via ``setSubviews(_:)`` (and only them) can be referenced in this text by index using
	/// ``ViewIndexAttribute`` attribute on a placeholder character (which is typically a Unicode
	/// Object Replacement Character, `\u{FFFC}`; see ``PlaceholderCharacter``).
	public var text: NSAttributedString = .init(string: "") {
		didSet {
			resetTextFrame()
		}
	}

	private func runDelegate(_ r: ManagedView) -> CTRunDelegate {
		// The delegate uses C functions, not blocks, so we need to manage some context for it.
		struct Metrics {
			var width, ascent, descent: CGFloat
		}
		let metrics = UnsafeMutablePointer<Metrics>.allocate(capacity: 1)
		// Note that at this point we assume that layout of subviews was performed and guides got their sizes.
		metrics.pointee = .init(
			width: r.boundsGuide.layoutFrame.width,
			ascent: r.ascentGuide.layoutFrame.height,
			descent: r.boundsGuide.layoutFrame.height - r.ascentGuide.layoutFrame.height
		)
		var callbacks = CTRunDelegateCallbacks(
			version: kCTRunDelegateCurrentVersion,
			dealloc: { $0.deallocate() },
			getAscent: { $0.assumingMemoryBound(to: Metrics.self).pointee.ascent },
			getDescent: { $0.assumingMemoryBound(to: Metrics.self).pointee.descent },
			getWidth: { $0.assumingMemoryBound(to: Metrics.self).pointee.width }
		)
		guard let runDelegate = CTRunDelegateCreate(&callbacks, metrics) else {
			preconditionFailure()
		}
		return runDelegate
	}

	private let ManagedViewAttribute = NSAttributedString.Key("MMMTextLayout.ManagedView")

	/// The value of this attribute should be an index (`Int`) of the subview to position at the corresponding
	/// location in the text.
	public static let ViewIndexAttribute = NSAttributedString.Key("MMMTextLayout.ViewIndex")

	/// The Object Replacement Character character (`\u{FFFC}`) that can be used to mark where a subview needs to be
	/// placed within the ``text``. (You can use other characters, but this one is recommended by CoreText.)
	/// It's not enough to simply insert that character to refer a subview, the index of it should be defined
	/// via ``ViewIndexAttribute`` attribute.
	public static let PlaceholderCharacter = "\u{FFFC}"

	/// An attributed string consisting of a single ``PlaceholderCharacter`` with optional `attributes`
	/// and with the value of ``ViewIndexAttribute`` on it set to `index`.
	public static func placeholderForView(
		_ index: Int,
		attributes: [NSAttributedString.Key : Any] = [:]
	) -> NSAttributedString {
		.init(
			string: Self.PlaceholderCharacter,
			attributes: [ Self.ViewIndexAttribute: index ]
				.merging(attributes, uniquingKeysWith: { a, b in a })
		)
	}

	private func makeAttributedString() -> NSAttributedString {
		let s = text.mutableCopy() as! NSMutableAttributedString
		s.enumerateAttribute(
			Self.ViewIndexAttribute,
			in: .init(location: 0, length: s.string.count),
			options: .longestEffectiveRangeNotRequired
		) { value, range, _ in
			guard let value else {
				// We are going to encounter ranges without our attribute.
				return
			}
			guard let index = value as? Int, 0 <= index else {
				assertionFailure("Values of ViewIndexAttribute should be non-negative integers")
				return
			}
			guard index < managedViews.count else {
				// Ignoring unknown views: it could be that the text is set before the views.
				return
			}
			let r = managedViews[index]
			s.addAttributes(
				[
					(kCTRunDelegateAttributeName as NSAttributedString.Key): runDelegate(r),
					ManagedViewAttribute: r
				],
				range: range
			)
		}
		return s
	}

	private func resetTextFrame() {
		textFrame = nil
		topMargin = 0
		_intrinsicContentSize = nil
		setNeedsLayout()
	}

	private var textFrame: CTFrame?
	private var textFrameSize: CGSize = .zero

	private func linesAndOrigins(_ textFrame: CTFrame) -> [(CTLine, CGPoint)] {

		let lines = CTFrameGetLines(textFrame) as! [CTLine]

		var origins: [CGPoint] = .init(repeating: .zero, count: lines.count)
		CTFrameGetLineOrigins(textFrame, .init(location: 0, length: 0), &origins)

		let origin = CTFrameGetPath(textFrame).boundingBoxOfPath.origin
		return Array(zip(lines, origins.map { CGPoint(x: origin.x + $0.x, y: origin.y + $0.y) }))
	}

	private func textLayout(
		_ framesetter: CTFramesetter,
		_ textFrameSize: CGSize
	) -> (textFrame: CTFrame, linesAndOrigins: [(CTLine, CGPoint)], topMargin: CGFloat)? {
		// Note that the docs say that the creation of the frame can fail, but Swift mapping does not make it optional.
		let textFrame: CTFrame? = CTFramesetterCreateFrame(
			framesetter,
			.init(location: 0, length: 0),
			CGPath(rect: .init(size: textFrameSize), transform: nil),
			nil
		)
		guard let textFrame else {
			return nil
		}
		let linesAndOrigins = linesAndOrigins(textFrame)
		let firstLineBounds = LineBounds(linesAndOrigins.first)
		let topMargin = textFrameSize.height - (firstLineBounds.origin.y + firstLineBounds.ascent).rounded(.toNearestOrAwayFromZero)
		return (textFrame, linesAndOrigins, topMargin)
	}

	public override func sizeThatFits(_ size: CGSize) -> CGSize {

		// To make sure managed subviews got their preferred sizes.
		// This is not needed in updateTextFrame() which is called after the layout pass.
		layoutIfNeeded()

		let framesetter = CTFramesetterCreateWithAttributedString(makeAttributedString())
		let textFrameSize = CGSize(
			width: size.width <= 0 || !size.width.isFinite ? .infinity : size.width.rounded(.down),
			height: 10_000
		)
		let layout = textLayout(framesetter, textFrameSize)
		let result = CTFramesetterSuggestFrameSizeWithConstraints(
			framesetter, .init(location: 0, length: 0), nil, textFrameSize, nil
		)
		let topMargin = shouldTrimLeading ? (layout?.topMargin ?? 0) : 0
		return .init(result.width.rounded(.up), result.height.rounded(.up) -  topMargin)
	}

	private func updateTextFrame() {

		let framesetter = CTFramesetterCreateWithAttributedString(makeAttributedString())

		// All views are initially hidden, just in case they are not mentioned in the template or don't fit.
		for r in managedViews {
			r.view.isHidden = true
		}

		let roundedWidth = bounds.width.rounded(.up)
		let roundedHeight = bounds.height.rounded(.up)

		// We need an extra pass when trimming the leading: an "unlimited" frame ensures at least one line fits
		// to capture the margin, while the actual height is needed later to make sure only fitting lines are visible.
		let preLayout = shouldTrimLeading ? textLayout(framesetter, .init(roundedWidth, 10_000)) : nil

		self.topMargin = preLayout?.topMargin ?? 0

		self.textFrameSize = .init(roundedWidth, roundedHeight + self.topMargin)
		let layout = textLayout(framesetter, self.textFrameSize)
		guard let layout else {
			// It is possible that the frame is not created when layout is too complex.
			firstLineBounds = .init()
			lastLineBounds = .init()
			updateBaselineLayout()
			topMargin = 0
			_intrinsicContentSize = nil
			return
		}

		self.textFrame = layout.textFrame

		let linesAndOrigins = layout.linesAndOrigins

		self.firstLineBounds = .init(linesAndOrigins.first)
		self.lastLineBounds = .init(linesAndOrigins.last)
		updateBaselineLayout()

		// Now we need to find runs corresponding to our placeholders and extract info on their positions.
		// Simply enumerating all runs is OK for now as we don't expect large text.
		for lineAndOrigin in linesAndOrigins {
			let (line, lineOrigin) = lineAndOrigin
			for run in CTLineGetGlyphRuns(line) as! [CTRun] {
				let runAttributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
				guard let record = runAttributes[ManagedViewAttribute] as? ManagedView else {
					continue
				}

				var runOrigin: CGPoint = .zero
				CTRunGetPositions(run, .init(location: 0, length: 1), &runOrigin)

				record.leftConstraint.constant = lineOrigin.x + runOrigin.x
				// We are rounding vertical position of each baseline here and when drawing them to avoid
				// single pixel misalignments caused by rounding in Auto Layout.
				record.baselineConstraint.constant = textFrameSize.height - (lineOrigin.y + runOrigin.y).rounded(.toNearestOrAwayFromZero) - topMargin

				// Once the view is referenced we can show it.
				record.view.isHidden = false
			}
		}

		func measure(_ w: CGFloat, _ h: CGFloat) -> CGSize {
			CTFramesetterSuggestFrameSizeWithConstraints(framesetter, .init(location: 0, length: 0), nil, .init(w, h), nil)
		}
		_intrinsicContentSize = .init(
			measure(CGFLOAT_MAX, CGFLOAT_MAX).width.rounded(.up),
			measure(textFrameSize.width, CGFLOAT_MAX).height.rounded(.up) - topMargin
		)
	}

	private struct LineBounds {

		public var origin: CGPoint = .zero
		public var width: CGFloat = 0
		public var leading: CGFloat = 0
		public var ascent: CGFloat = 0
		public var descent: CGFloat = 0

		public init(_ pair: (CTLine, CGPoint)?) {
			if let pair {
				self.init(line: pair.0, origin: pair.1)
			} else {
				self.init()
			}
		}

		public init(line: CTLine, origin: CGPoint) {
			self.origin = origin
			self.width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
		}

		public init() {}
	}

	private var firstLineBounds = LineBounds()
	private var lastLineBounds = LineBounds()

	// We are not exposing trimming via `alignmentRectInsets` anymore as that does not play well with SwiftUI layout.
	private var topMargin: CGFloat = 0

	private struct BaselineLayout {
		var view: MMMSpacerView
		var firstConstraint: NSLayoutConstraint
		var lastConstraint: NSLayoutConstraint
	}

	private var baselineLayout: BaselineLayout?

	private func grabBaselineLayout() -> BaselineLayout {
		if let baselineLayout {
			return baselineLayout
		}
		let view = MMMSpacerView()
		let baselineLayout = BaselineLayout(
			view: view,
			firstConstraint: view.topAnchor.constraint(equalTo: self.topAnchor),
			lastConstraint: view.bottomAnchor.constraint(equalTo: self.topAnchor)
		)
		addSubview(view)
		NSLayoutConstraint.activate([baselineLayout.firstConstraint, baselineLayout.lastConstraint])
		self.baselineLayout = baselineLayout
		updateBaselineLayout()
		return baselineLayout
	}

	private func updateBaselineLayout() {
		guard let baselineLayout else {
			return
		}
		baselineLayout.firstConstraint.constant = textFrameSize.height - firstLineBounds.origin.y.rounded(.toNearestOrAwayFromZero) - topMargin
		baselineLayout.lastConstraint.constant = textFrameSize.height - lastLineBounds.origin.y.rounded(.toNearestOrAwayFromZero) - topMargin
	}

	public override var intrinsicContentSize: CGSize {
		if let _intrinsicContentSize {
			return _intrinsicContentSize
		}
		updateTextFrame()
		return _intrinsicContentSize ?? .zero
	}

	private var _intrinsicContentSize: CGSize? {
		didSet {
			if _intrinsicContentSize != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}

	public override var forLastBaselineLayout: UIView {
		grabBaselineLayout().view
	}

	public override func layoutSubviews() {
		updateTextFrame()
		invalidateIntrinsicContentSize()
		super.layoutSubviews()
	}

	public override func draw(_ rect: CGRect) {

		guard let textFrame, let context = UIGraphicsGetCurrentContext() else {
			return
		}

		context.saveGState()
		context.translateBy(x: 0, y: textFrameSize.height - topMargin)
		context.scaleBy(x: 1, y: -1)

		// We cannot just use CTFrameDraw() here, because we want all baselines to be rounded to avoid single pixel
		// misalignments caused by Auto Layout rounding.
		for lineAndOrigin in linesAndOrigins(textFrame) {
			var (line, lineOrigin) = lineAndOrigin
			lineOrigin.y += lineOrigin.y.rounded(.toNearestOrAwayFromZero) - lineOrigin.y
			context.textPosition = lineOrigin
			CTLineDraw(line, context)
		}

		context.restoreGState()
	}
}
