//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2025 Monks. All rights reserved.
//

import Foundation

extension NSAttributedString {

	/// Builds an attributed string out of a plain template string and attributes, replacing placeholders like 
	/// `%@` or `%2$@` in it with attributed strings from `args`.
	///
	/// - Parameters:
	///
	///   - format: The usual formatting template string with regular (`%@`) or positional string placeholders (`%1$@`).
	///
	///     Note that non-string placeholders like `%d` are not supported!
	///
	///   - attributes: The attributes that all parts of the `format` string except placeholders are going to have.
	///
	///   - args: The attributed strings that should be used instead of placeholders.
	///
	///     Note that the attributes of these strings completely replace those in `attributes`.
	///
	///   - invalidPlaceholder: The closure that is called for placeholders having no matching strings in `args`.
	///     The zero-based index of the placeholder is passed and the returned value is used for this invalid placeholder.
	///
	///     If this is not provided, then invalid placeholders are deleted.
	///
	///     This allows to make a wrapper that stops in Debug releases to notice the issue earlier; it also allows to return something
	///     different from an empty string for for testing purposes.
	public convenience init(
		format: String,
		attributes: [NSAttributedString.Key: Any],
		args: [NSAttributedString],
		invalidPlaceholder: ((_ index: Int) -> NSAttributedString)? = nil
	) {
		// NSString is easier and safer when regular expressions and ranges are involved.
		let _format = format as NSString

		let output = NSMutableAttributedString()

		var nextArgIndex = 0
		var prefixStart = 0

		Self.placeholderRegex.enumerateMatches(
			in: _format as String,
			options: [],
			range: NSRange(location: 0, length: _format.length)
		) { (result, flags, stop) in

			guard let r = result?.range else {
				// When can it be nil exactly?
				assertionFailure()
				return
			}

			let argumentIndex: Int = {
				// Is this a placeholder specifying a 1-based argument index, like i in `%i$@`?
				guard let positionRange = result?.range(withName: "position"), positionRange.location != NSNotFound else {
					// Well, must be a regular `%@` placeholder, so just taking the next unused argument.
					let position = nextArgIndex
					nextArgIndex += 1
					return position
				}
				guard let position = Int(_format.substring(with: positionRange)) else {
					// We capture only digits there, so should not fail.
					preconditionFailure()
				}
				return position - 1
			}()

			let argument: NSAttributedString
			if args.indices.contains(argumentIndex) {
				argument = args[argumentIndex]
			} else {
				argument = invalidPlaceholder?(argumentIndex) ?? NSAttributedString()
			}

			let beforePlaceholder = _format.substring(with: .init(location: prefixStart, length: r.location - prefixStart))
			output.append(.init(string: beforePlaceholder, attributes: attributes))
			prefixStart = r.location + r.length
			output.append(argument)
		}

		// The remaining part of the formatting string after the last placeholder, if any.
		let suffix = _format.substring(with: .init(location: prefixStart, length: _format.length - prefixStart))
		output.append(.init(string: suffix, attributes: attributes))

		self.init(attributedString: output)
	}

	private static var placeholderRegex = try! NSRegularExpression(pattern: "%((?<position>\\d+)\\$)?@", options: [])
}
