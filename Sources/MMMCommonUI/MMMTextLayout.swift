//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2025 Monks. All rights reserved.
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
public class MMMTextLayout: NonStoryboardableView {

	public override init() {
		super.init()
		self.isOpaque = false
		self.contentMode = .redraw
	}

	private struct ManagedView {
		var view: UIView
		var boundsGuide: UILayoutGuide
		var ascentGuide: UILayoutGuide
		var leftConstraint: NSLayoutConstraint
		var topConstraint: NSLayoutConstraint
	}

	private var managedViews: [ManagedView] = []

	/// The views to layout.
	///
	/// Only the subviews added via this method can be referenced from ``text`` and participate in the layout.
	/// The receiver controls both the position and the visibility of these views: the ones that are not referenced
	/// from ``text`` or the part of it that is actually visible are going to be automatically hidden.
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
				// The constants of both of these constraints are updated to position the views.
				leftConstraint: view.leftAnchor.constraint(equalTo: self.leftAnchor),
				// It's convenient to offset from the bottom as layout in CoreText is flipped.
				topConstraint: self.bottomAnchor.constraint(equalTo: view.firstBaselineAnchor)
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
				r.topConstraint,
				// One guide will give us width/height of the view without the need to size it separately.
				r.boundsGuide.widthAnchor.constraint(equalTo: r.view.widthAnchor, multiplier: 1),
				r.boundsGuide.heightAnchor.constraint(equalTo: r.view.heightAnchor, multiplier: 1),
				// And another one is needed for the baseline info, i.e. ascent/descent.
				r.ascentGuide.topAnchor.constraint(equalTo: r.view.topAnchor),
				r.ascentGuide.bottomAnchor.constraint(equalTo: r.view.firstBaselineAnchor)
			])
		}
		resetFramesetter()
	}

	/// The attributed text to render.
	///
	/// The subviews set via ``setSubviews(_:)`` (and only them) can be referenced in this text by index using
	/// ``ViewIndexAttribute`` attribute on a placeholder character (which is typically a Unicode
	/// Object Replacement Character, `\u{FFFC}`; see ``PlaceholderCharacter``).
	public var text: NSAttributedString = .init(string: "") {
		didSet {
			resetFramesetter()
		}
	}

	private func runDelegate(_ r: ManagedView) -> CTRunDelegate {
		// The delegate uses C functions, not blocks, so we need to manage some context for it.
		struct Metrics {
			var width, ascent, descent: CGFloat
		}
		let metrics = UnsafeMutablePointer<Metrics>.allocate(capacity: 1)
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

	private let RecordAttribute = NSAttributedString.Key("MMMTextLayout.ManagedView")

	/// The value of this attribute should be an index (`Int`) of the subview to position at the corresponding
	/// location in the text.
	public static let ViewIndexAttribute = NSAttributedString.Key("MMMTextLayout.ViewIndex")

	/// The Object Replacement Character character (`\u{FFFC}`) that can be used to mark where a subview needs to be
	/// placed within the ``text``. (You can use other characters, but this one is recommended by CoreText.)
	/// It's not enough to simply insert that character to refer a subview, the index of it should be defined
	/// via ``ViewIndexAttribute`` attribute.
	public static let PlaceholderCharacter = "\u{FFFC}"

	/// An attributed string consisting of a single ``PlaceholderCharacter`` with value of
	/// ``ViewIndexAttribute`` on it set to ``index``.
	public static func placeholderForView(_ index: Int) -> NSAttributedString {
		.init(string: Self.PlaceholderCharacter, attributes: [ Self.ViewIndexAttribute: index ])
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
					RecordAttribute: r
				],
				range: range
			)
		}
		return s
	}

	private var framesetter: CTFramesetter?

	private func grabFramesetter() -> CTFramesetter {
		if let framesetter {
			return framesetter
		} else {
			let framesetter = CTFramesetterCreateWithAttributedString(makeAttributedString())
			self.framesetter = framesetter
			return framesetter
		}
	}

	private func resetFramesetter() {
		self.framesetter = nil
		self.textFrame = nil
		invalidateIntrinsicContentSize()
		setNeedsLayout()
		setNeedsDisplay()
	}

	private var textFrame: CTFrame?

	private func updateTextFrame() {

		self.setNeedsDisplay()

		let framesetter = grabFramesetter()

		// All views are initially hidden, just in case they are not mentioned in the template or don't fit.
		for r in managedViews {
			r.view.isHidden = true
		}

		self.textFrame = CTFramesetterCreateFrame(
			framesetter,
			.init(location: 0, length: 0), // 0 length for the whole string.
			CGPath(rect: bounds, transform: nil),
			nil // No extra attributes.
		)
		guard let textFrame else {
			// It is possible that the frame is not created when layout is too complex.
			return
		}

		// Now we need to find runs corresponding to our placeholders and extract info on their positions.
		// Simply enumerating all runs is OK for now as we don't expect large text.
		let lines = CTFrameGetLines(textFrame) as! [CTLine]
		var lineOrigins: [CGPoint] = .init(repeating: .zero, count: lines.count)
		CTFrameGetLineOrigins(textFrame, .init(location: 0, length: 0), &lineOrigins)
		let origin = CTFrameGetPath(textFrame).boundingBoxOfPath.origin
		for lineAndOrigin in zip(lines, lineOrigins) {
			let (line, lineOrigin) = lineAndOrigin
			for run in CTLineGetGlyphRuns(line) as! [CTRun] {
				let runAttributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
				guard let record = runAttributes[RecordAttribute] as? ManagedView else {
					continue
				}
				var runOrigin: CGPoint = .zero
				CTRunGetPositions(run, .init(location: 0, length: 1), &runOrigin)

				record.leftConstraint.constant = origin.x + lineOrigin.x + runOrigin.x
				record.topConstraint.constant = origin.y + lineOrigin.y + runOrigin.y

				// Once the view is referenced and we can show it.
				record.view.isHidden = false
			}
		}
	}

	private var _intrinsicContentSize: (size: CGSize, boundsWidth: CGFloat)?

	public override func invalidateIntrinsicContentSize() {
		_intrinsicContentSize = nil
		super.invalidateIntrinsicContentSize()
	}

	public override var intrinsicContentSize: CGSize {

		let width = bounds.width
		if let _intrinsicContentSize, _intrinsicContentSize.boundsWidth == width {
			return _intrinsicContentSize.size
		}

		let framesetter = grabFramesetter()
		func sizeWithConstraints(_ size: CGSize) -> CGSize {
			CTFramesetterSuggestFrameSizeWithConstraints(framesetter, .init(location: 0, length: 0), nil, size, nil)
		}
		let size = CGSize(
			width: sizeWithConstraints(.init(width: CGFLOAT_MAX, height: CGFLOAT_MAX)).width.rounded(.up),
			height: sizeWithConstraints(.init(width: width, height: CGFLOAT_MAX)).height.rounded(.up)
		)
		self._intrinsicContentSize = (size: size, boundsWidth: width)
		return size
	}

	public override func layoutSubviews() {
		if _intrinsicContentSize?.boundsWidth != bounds.width {
			invalidateIntrinsicContentSize()
		}
		updateTextFrame()
		super.layoutSubviews()
	}

	public override func draw(_ rect: CGRect) {
		guard let textFrame else {
			return
		}
		guard let context = UIGraphicsGetCurrentContext() else {
			preconditionFailure()
		}
		context.saveGState()
		context.translateBy(x: 0, y: bounds.maxY)
		context.scaleBy(x: 1, y: -1)
		CTFrameDraw(textFrame, context)
		context.restoreGState()
	}
}
