//
// Starbucks App.
// Copyright (c) 2023 MediaMonks. All rights reserved.
// 

import UIKit
import MMMLog

@objc public protocol MMMNavigationStackHelperToken {
	func markAsDismissed()
}

extension UIViewController {

	public typealias MMMNavigationDismissRequestCompletion = (_ successfully: Bool) -> Void
	public typealias MMMNavigationDismissRequest = (_ didDismiss: @escaping MMMNavigationDismissRequestCompletion) -> Void

	public enum MMMExternalDismissRequest {
		/// Reject all requests to programmatically dismiss the corresponding view controller.
		case decline
		/// It's enough to call ``UIViewController.dismiss(animated:completion:)`` to programmatically dismiss
		/// the corresponding view controller, no extra steps necessary.
		case justDismiss
		/// It's enough to call ``UIViewController.dismiss(animated:completion:)`` followed by a few synchronous
		/// instructions to programmatically dismiss the corresponding view controller.
		case dismissThen(() -> Void)
		/// A custom piece of code is needed to dismiss the corresponding view controller. The code receives a
		/// `didDismiss` that must be eventually called after the dismissal completes (or cannot be completed).
		case custom(MMMNavigationDismissRequest)
	}

	/// A drop-in replacement for `UIViewController.present(_:animated:completion:)` recording the presentation
	/// with ``MMMNavigationStack`` to properly dismiss the view controller when the app needs to programmatically
	/// unwind the current UI flow to navigate somewhere else (e.g. while opening a deep link).
	///
	/// - Parameter onExternalDismissRequest:
	/// 	Describes what needs to be done to programmatically dismiss the view controller being presented
	/// 	while programmatically unwinding the UI.
	///
	/// - Returns:
	/// 	The token that can be used to properly update ``MMMNavigationStack`` in case the view controller cannot
	/// 	be dismissed via matching ``UIViewController.mmm_dismiss(animated:completion:)``.
	///
	/// This method needs to be used in conjunction with ``UIViewController.mmm_dismiss(animated:completion:)`` replacing
	/// ``UIViewController.dismiss(animated:completion:)`` or, when that's not possible, while timely marking
	/// the view controller as dismissed via a call to ``MMMNavigationStackHelperToken.markAsDismissed()`` on the
	/// returned token.
	@discardableResult
	public func mmm_present(
		_ viewController: UIViewController,
		animated: Bool,
		onExternalDismissRequest: MMMExternalDismissRequest,
		completion: (() -> Void)? = nil
	) -> MMMNavigationStackHelperToken? {

		present(viewController, animated: animated, completion: completion)

		// Assuming that `presentingViewController` is set after the above call.
		guard let presentingViewController = viewController.presentingViewController else {
			assertionFailure("Could not present \(MMMTypeName(viewController)) via \(MMMTypeName(self))?")
			return nil
		}

		return MMMNavigationStackHelper.instanceFor(presentingViewController).push(
			viewController: viewController,
			externalDismissRequest: {
				switch onExternalDismissRequest {
				case .justDismiss:
					return { [weak viewController] didDismiss in
						guard let viewController = viewController else {
							assertionFailure("Trying to dismiss a view controller that is gone already?")
							return
						}
						viewController.mmm_dismiss(animated: true) {
							didDismiss(true)
						}
					}
				case .dismissThen(let callback):
					return { [weak viewController] didDismiss in
						guard let viewController = viewController else {
							assertionFailure("Trying to dismiss a view controller that is gone already?")
							return
						}
						viewController.mmm_dismiss(animated: true) {
							callback()
							didDismiss(true)
						}
					}
				case .decline:
					return { didDismiss in
						didDismiss(false)
					}
				case .custom(let callback):
					return callback
				}
			}()
		)
	}

	/// ObjC-friendly version of ``mmm_present(_:animated:onExternalDismissRequest:completion:)``.
	@objc(mmm_presentViewController:animated:onExternalDismissRequest:completion:)
	public func mmm_present(
		_ viewController: UIViewController,
		animated: Bool,
		onExternalDismissRequest: @escaping MMMNavigationDismissRequest,
		completion: (() -> Void)? = nil
	) -> MMMNavigationStackHelperToken? {
		self.mmm_present(
			viewController,
			animated: animated,
			onExternalDismissRequest: .custom(onExternalDismissRequest),
			completion: completion
		)
	}

	/// A drop-in replacement for ``UIViewController.dismiss(animated:completion:)`` to be used in conjunction with
	/// ``mmm_present(_:animated:onExternalDismissRequest:completion:)``. Check the latter for more info.
	///
	/// It should be safe to call this even for the view controllers that were not presented via
	/// ``mmm_present(_:animated:onExternalDismissRequest:completion:)`` (though you'll get a trace in the logs).
	@objc(mmm_dismissAnimated:completion:)
	public func mmm_dismiss(
		animated flag: Bool,
		completion: (() -> Void)? = nil
	) {
		// I am not quite sure about the logic of dismiss() call, but this should be enough for our use cases.
		let viewControllerToBeDismissed = self.presentedViewController ?? self
		guard let presentingViewController = viewControllerToBeDismissed.presentingViewController else {
			assertionFailure("Could not figure out the presenting view controller for \(MMMTypeName(viewControllerToBeDismissed))")
			self.dismiss(animated: flag, completion: completion)
			return
		}

		self.dismiss(animated: flag) {
			MMMNavigationStackHelper.instanceFor(presentingViewController).pop(viewControllerToBeDismissed)
			completion?()
		}
	}

	/// Should be used to properly update the state of ``MMMNavigationStack`` after a view controller presented
	/// via ``UIViewController.mmm_present(_:animated:onExternalDismissRequest:completion:)`` is dismissed without
	/// the use of a matching ``UIViewController.mmm_dismiss(animated:completion:)`` call.
	///
	/// This is an alternative to ``MMMNavigationStackHelperToken.markAsDismissed()`` called on the token
	/// returned by ``UIViewController.mmm_present(_:animated:onExternalDismissRequest:completion:)``,
	/// which might not always be convenient. Note however that this must to be called on the actual presenting
	/// view controller which is not always the same as the view controller receiving the `mmm_present` call!
	@objc(mmm_markViewControllerAsDismissed:)
	public func mmm_markAsDismissed(_ viewController: UIViewController) {
		MMMNavigationStackHelper.instanceFor(self).pop(viewController)
	}
}

private class MMMNavigationStackHelper: NSObject, MMMNavigationStackItemDelegate, MMMLogSource {

	public let logContext: String = "MMMNavigationStackHelper"

	private static var key: Int = 110 // In percents.

	public static func instanceFor(_ obj: NSObject) -> MMMNavigationStackHelper {
		if let helper = objc_getAssociatedObject(obj, &key) as? MMMNavigationStackHelper {
			return helper
		}
		let helper = MMMNavigationStackHelper()
		objc_setAssociatedObject(obj, &key, helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return helper
	}

	private class Record {

		public let navigationItem: MMMNavigationStackItem
		public private(set) weak var viewController: UIViewController?
		public let externalDismissRequest: UIViewController.MMMNavigationDismissRequest

		internal init(
			navigationItem: MMMNavigationStackItem,
			viewController: UIViewController?,
			externalDismissRequest: @escaping UIViewController.MMMNavigationDismissRequest
		) {
			self.navigationItem = navigationItem
			self.viewController = viewController
			self.externalDismissRequest = externalDismissRequest
		}
	}

	private var records: [Record] = []

	public func push(
		viewController: UIViewController,
		externalDismissRequest: @escaping UIViewController.MMMNavigationDismissRequest
	) -> MMMNavigationStackHelperToken? {

		let item = MMMNavigationStack.shared().pushItem(
			name: MMMTypeName(viewController),
			delegate: self,
			controller: viewController
		)
		guard let item else {
			// It's possible that the push is not successful, this will be logged by the stack.
			return nil
		}

		let record = Record(
			navigationItem: item,
			viewController: viewController,
			externalDismissRequest: externalDismissRequest
		)

		records.append(record)

		return Token(helper: self, record: record)
	}

	public func pop(_ viewController: UIViewController) {

		if let recordPoppingNow {
			if recordPoppingNow.viewController === viewController {
				// The record is already removed as part of the pop request, nothing to do here.
				return
			} else {
				MMMLogError(self, "Trying to remove a record for a \(MMMTypeName(viewController)) while popping a different instance (\(MMMTypeName(recordPoppingNow.viewController)))")
				assertionFailure()
				// It would be a weird case, but let it continue in production.
			}
		}

		guard let record = records.last, record.viewController === viewController else {
			MMMLogTrace(self, "Trying to remove a record for a \(MMMTypeName(viewController)) when it's not on top or does not exist")
			// Not asserting here because we want mmm_dismiss() to be safe to call with view controllers
			// that were not presented with mmm_present.
			return
		}
		record.navigationItem.didPop()
		records.removeLast()
	}

	private var recordPoppingNow: Record?

	public func pop(_ item: MMMNavigationStackItem) {

		guard
			let record = records.last,
			record.navigationItem === item,
			recordPoppingNow == nil
		else {
			MMMLogError(self, "Trying to pop an item that's not on top in our records or while popping something already")
			item.didFailToPop()
			assertionFailure()
			return
		}

		recordPoppingNow = record
		records.removeLast()

		record.externalDismissRequest { [weak self] succeeded in

			guard let self = self else { return }

			guard self.recordPoppingNow === record else {
				// Can happen in case markAsPopped was called in the meantime.
				return
			}

			self.recordPoppingNow = nil

			if succeeded {
				record.navigationItem.didPop()
			} else {
				record.navigationItem.didFailToPop()
			}
		}
	}

	private func markAsPopped(_ record: Record) {

		records.removeAll { $0 === record }

		if recordPoppingNow === record {
			recordPoppingNow = nil
		}

		record.navigationItem.didPop()
	}

	@objc private class Token: NSObject, MMMNavigationStackHelperToken {

		private let helper: MMMNavigationStackHelper
		private let record: Record

		public init(helper: MMMNavigationStackHelper, record: Record) {
			self.helper = helper
			self.record = record
		}

		public func markAsDismissed() {
			helper.markAsPopped(record)
		}
	}
}
