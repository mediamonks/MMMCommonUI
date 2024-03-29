//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 * Auto Layout does not support relationships between empty spaces, so we need to use spacer views and set such
 * constraints between them. This one is a transparent and by default hidden view which can be used as such a spacer.
 * It has no intrinsic size and low content hugging and compression resistance priorities.
 * Unlike UIView we have translatesAutoresizingMaskIntoConstraints set to NO already.
 */
@interface MMMSpacerView : UIView

- (nonnull id)init NS_DESIGNATED_INITIALIZER;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

/** General alignment flags used when it's not important which direction (vertical or horizontal) the alignment is for. */
typedef NS_ENUM(NSInteger, MMMLayoutAlignment) {
	MMMLayoutAlignmentNone,
	MMMLayoutAlignmentLeading,
	MMMLayoutAlignmentGolden,
	MMMLayoutAlignmentCenter,
	MMMLayoutAlignmentTrailing,
	MMMLayoutAlignmentFill
};

typedef NS_ENUM(NSInteger, MMMLayoutDirection) {
	MMMLayoutDirectionHorizontal,
	MMMLayoutDirectionVertical
};

typedef NS_ENUM(NSInteger, MMMLayoutHorizontalAlignment) {
	MMMLayoutHorizontalAlignmentNone = MMMLayoutAlignmentNone,
	MMMLayoutHorizontalAlignmentLeft = MMMLayoutAlignmentLeading,
	MMMLayoutHorizontalAlignmentGolden = MMMLayoutAlignmentGolden,
	MMMLayoutHorizontalAlignmentCenter = MMMLayoutAlignmentCenter,
	MMMLayoutHorizontalAlignmentRight = MMMLayoutAlignmentTrailing,
	MMMLayoutHorizontalAlignmentFill = MMMLayoutAlignmentFill
};

typedef NS_ENUM(NSInteger, MMMLayoutVerticalAlignment) {
	MMMLayoutVerticalAlignmentNone = MMMLayoutAlignmentNone,
	MMMLayoutVerticalAlignmentTop = MMMLayoutAlignmentLeading,
	MMMLayoutVerticalAlignmentGolden = MMMLayoutAlignmentGolden,
	MMMLayoutVerticalAlignmentCenter = MMMLayoutAlignmentCenter,
	MMMLayoutVerticalAlignmentBottom = MMMLayoutAlignmentTrailing,
	MMMLayoutVerticalAlignmentFill = MMMLayoutAlignmentFill
};

static inline MMMLayoutAlignment MMMLayoutAlignmentFromHorizontalAlignment(MMMLayoutHorizontalAlignment alignment) {
	return (MMMLayoutAlignment)alignment;
}

static inline MMMLayoutAlignment MMMLayoutAlignmentFromVerticalAlignment(MMMLayoutVerticalAlignment alignment) {
	return (MMMLayoutAlignment)alignment;
}

//
//
//
@interface UILayoutGuide (MMMTemple)

/// Convenience initializer setting the guide's identifier.
- (id)initWithIdentifier:(NSString *)identifier;

/**
 * Not yet activated constraints anchoring the given view within the receiver according to horizontal
 * and vertical alignment flags.
 */
- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningView:(UIView *)view
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets NS_SWIFT_NAME(mmm_constraints(aligning:horizontally:vertically:insets:));

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningGuide:(UILayoutGuide *)guide
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets NS_SWIFT_NAME(mmm_constraints(aligning:horizontally:vertically:insets:));

/**
 * Not yet activated constraints implementing a common layout idiom used with text:
 * - the given view is centered within the receiver,
 * - certain minimum padding is ensured on the sides,
 * - if `maxWidth > 0`, then the width of the view is limited to `maxWidth`, so it does not grow too wide e.g. on iPad.
 */
- (NSArray<NSLayoutConstraint *> *)mmm_constraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
	maxWidth:(CGFloat)maxWidth NS_SWIFT_NAME(mmm_constraints(horizontallyCentering:minPadding:maxWidth:));

@end

/** 
 * A few shorthands for UIView.
 */
@interface UIView (MMMTemple)

/** A wrapper for the `center` and `bounds.size` properties similar to 'frame', but not taking the current transform into account. 
 * Handy when there is a transform applied to a view already, but we want to set its frame in normal state. */
@property (nonatomic, setter=mmm_setRect:) CGRect mmm_rect;

/** A wrapper for the `size` component of `bounds` property. */
@property (nonatomic, setter=mmm_setSize:) CGSize mmm_size;

/** A safer version of `safeAreaLayoutGuide` that attempts to avoid layout loops happening when a view using it
  * is transformed in certain "inconvenient" way. (Apple Feedback ID: FB7609936.) */
@property (nonatomic, readonly) UILayoutGuide *mmm_safeAreaLayoutGuide;

/** Effective `safeAreaInsets` as seen by `mmm_safeAreaLayoutGuide`. */
@property (nonatomic, readonly) UIEdgeInsets mmm_safeAreaInsets;

/**
 * Constraints anchoring the given view within the receiver according to horizontal and vertical alignment flags.
 * Note that constrains are not added into the reciever automatically.
 * It is recommended to use this method instead of the `mmm_addConstraintsForSubview:*` bunch.
 */
- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets;

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment DEPRECATED_ATTRIBUTE;

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningView:(UIView *)subview
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment DEPRECATED_ATTRIBUTE;

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningGuide:(UILayoutGuide *)guide
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets NS_SWIFT_NAME(mmm_constraints(aligning:horizontally:vertically:insets:));

/** 
 * Adds contraints anchoring the given view within the receiver according to horizontal and vertical alignment flags.
 * (This is a shortcut for calling mmm_constraintsAligningView:horizontally:vertically:insets: and adding the contraints returned.)
 */
- (NSArray<NSLayoutConstraint *> *)mmm_addConstraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets;

- (NSArray<NSLayoutConstraint *> *)mmm_addConstraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment;

- (NSArray<NSLayoutConstraint *> *)mmm_addConstraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment DEPRECATED_ATTRIBUTE;

- (NSArray<NSLayoutConstraint *> *)mmm_addConstraintsAligningView:(UIView *)subview
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment DEPRECATED_ATTRIBUTE;

/**
 * Not yet activated constraints implementing a common layout idiom used with text:
 * - the given view is centered within the receiver,
 * - certain minimum padding is ensured on the sides,
 * - if `maxWidth > 0`, then the width of the view is limited to `maxWidth`, so it does not grow too wide e.g. on iPad.
 */
- (NSArray<NSLayoutConstraint *> *)mmm_constraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
	maxWidth:(CGFloat)maxWidth NS_REFINED_FOR_SWIFT;

/** A shortcut activating constraints returned by `mmm_constraintsHorizontallyCenteringView:minPadding:maxWidth:`. */
- (void)mmm_addConstraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
	maxWidth:(CGFloat)maxWidth NS_REFINED_FOR_SWIFT;

/** A shortcut activating constraints returned by `mmm_constraintsHorizontallyCenteringView:minPadding:maxWidth:`
 * setting `maxWidth` to zero. */
- (void)mmm_addConstraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding NS_SWIFT_UNAVAILABLE("");

#pragma mark - To be deprecated soon

/**
 * Adds constraints anchoring the given subview within the receiver according to horizontal and vertical alignment flags.
 * The constraints are also returned, so the caller can remove them later, for example.
 */
- (NSArray<NSLayoutConstraint *> *)mmm_addConstraintsForSubview:(UIView *)subview
	horizontalAlignment:(UIControlContentHorizontalAlignment)horizontalAlignment
	verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
	DEPRECATED_ATTRIBUTE;

- (NSArray<NSLayoutConstraint *> *)mmm_addConstraintsForSubview:(UIView *)subview
	horizontalAlignment:(UIControlContentHorizontalAlignment)horizontalAlignment
	verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
	DEPRECATED_ATTRIBUTE;

#pragma mark -

/** 
 * Adds constraints and two hidden auxiliary views ensuring that the space between the top of the subview and
 * topAttribute of topItem is in 'ratio' proportion to the space between the bottom of the subview 
 * and bottomAttribute of bottomItem.
 *
 * To be clear:
 * 	 ratio = (top space) / (bottom space)
 *
 * So you need to use 1 when you want the same size, not 0.5, for example.
 *
 * The given priority will be used for the constraints between the heights of the aux views.
 */
- (void)mmm_addVerticalSpaceRatioConstraintsForSubview:(UIView *)subview
	topItem:(id)topItem topAttribute:(NSLayoutAttribute)topAttribute
	bottomItem:(id)bottomItem bottomAttribute:(NSLayoutAttribute)bottomAttribute
	ratio:(CGFloat)ratio
	priority:(UILayoutPriority)priority;

- (void)mmm_addVerticalSpaceRatioConstraintsForSubview:(UIView *)subview
	topItem:(id)topItem topAttribute:(NSLayoutAttribute)topAttribute
	bottomItem:(id)bottomItem bottomAttribute:(NSLayoutAttribute)bottomAttribute
	ratio:(CGFloat)ratio;

/** 
 * Adds constrains and a hidden auxiliary view ensuring that specified item / attribute vertically divides
 * the subview in the specified ratio. 
 * Unlike the previous function the ratio here is given not as (top space / bottom space), but as
 * (top space / (top space + bottom space)). Sorry for the confusion, deprecating this one for now.
 */
- (void)mmm_addVerticalSpaceRatioConstraintsForSubview:(UIView *)subview
	item:(id)item attribute:(NSLayoutAttribute)attribute
	ratio:(CGFloat)ratio DEPRECATED_ATTRIBUTE;

/** @{ */

/** Shortcuts for compression resistance and hugging priorities. */

- (void)mmm_setVerticalCompressionResistance:(UILayoutPriority)priority;
- (void)mmm_setHorizontalCompressionResistance:(UILayoutPriority)priority;

- (void)mmm_setVerticalHuggingPriority:(UILayoutPriority)priority;
- (void)mmm_setHorizontalHuggingPriority:(UILayoutPriority)priority;

- (void)mmm_setVerticalCompressionResistance:(UILayoutPriority)compressionResistance hugging:(UILayoutPriority)hugging DEPRECATED_ATTRIBUTE;
- (void)mmm_setHorizontalCompressionResistance:(UILayoutPriority)compressionResistance hugging:(UILayoutPriority)hugging DEPRECATED_ATTRIBUTE;

- (void)mmm_setCompressionResistanceHorizontal:(UILayoutPriority)horizontal
	vertical:(UILayoutPriority)vertical NS_SWIFT_NAME(mmm_setCompressionResistance(horizontal:vertical:));
	
- (void)mmm_setHuggingHorizontal:(UILayoutPriority)horizontal
	vertical:(UILayoutPriority)vertical NS_SWIFT_NAME(mmm_setHugging(horizontal:vertical:));

/** @} */

@end

@interface NSLayoutConstraint (MMMTemple)

/**
 * Our wrapper over the corresponding method of NSLayoutConstraint extending the visual layout language a bit to support
 * `safeAreaLayoutGuide` property introduced in iOS 11 and still be compatible with older versions of iOS.
 * (See also `mmm_safeAreaLayoutGuide` in our extension of UIView.)
 *
 * To use it simply replace a reference to the superview edge "|" with a reference to a safe edge "<|".
 *
 * For example, if you have the following pre iOS 9 code:
 *
 * \code
 * [NSLayoutConstraint activateConstraints:[NSLayoutConstraint
 *     constraintsWithVisualFormat:@"V:[_button]-(normalPadding)-|"
 *     options:0 metrics:metrics views:views
 * ]];
 * \endcode
 *
 * And now you want to make sure that the button sits above the safe bottom margin on iPhone X, then do this:
 *
 * \code
 * [NSLayoutConstraint activateConstraints:[NSLayoutConstraint
 *     mmm_constraintsWithVisualFormat:@"V:[_button]-(normalPadding)-<|"
 *     options:0 metrics:metrics views:views
 * ]];
 * \endcode
 *
 * That's it. It'll anchor the button to the bottom of its superview on iOS 9 and 10, but anchor it to the bottom of
 * its safeAreaLayoutGuide on iOS 11.
 *
 * Please note that using "|>" to pin to the top won't exclude the status bar on iOS 9 and 10.
 */
+ (NSArray<NSLayoutConstraint *> *)mmm_constraintsWithVisualFormat:(NSString *)format
	options:(NSLayoutFormatOptions)opts
	metrics:(nullable NSDictionary<NSString *,id> *)metrics
	views:(nullable NSDictionary<NSString *,id> *)views;

/** A shortcut for `[NSLayoutConstraint activateConstraints:[NSLayoutConstraint mmm_constraintsWithVisualFormat:...`. */
+ (void)mmm_activateConstraintsWithVisualFormat:(NSString *)format
	options:(NSLayoutFormatOptions)opts
	metrics:(nullable NSDictionary<NSString *,id> *)metrics
	views:(nullable NSDictionary<NSString *,id> *)views;

/** Missing counterparts for (de)activateConstraints, so constraint activation code looks the same for individual constraints. */
+ (void)activateConstraint:(NSLayoutConstraint *)constraint;
+ (void)deactivateConstraint:(NSLayoutConstraint *)constraint;

/** A missing convenience initializer including priority. */
+ (instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1
	relatedBy:(NSLayoutRelation)relation
	toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2
	multiplier:(CGFloat)multiplier constant:(CGFloat)c
	priority:(UILayoutPriority)priority;

/** A missing convenience initializer allowing to set identifier for this constraint. */
+ (instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1
	relatedBy:(NSLayoutRelation)relation
	toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2
	multiplier:(CGFloat)multiplier constant:(CGFloat)c
	identifier:(NSString *)identifier;

/** A missing convenience initializer allowing to set both priority and identifier for this constraint. */
+ (instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1
	relatedBy:(NSLayoutRelation)relation
	toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2
	multiplier:(CGFloat)multiplier constant:(CGFloat)c
	priority:(UILayoutPriority)priority
	identifier:(NSString *)identifier;

/** A missing convenience initializer allowing to tag a bunch of visual constraints with the same identifier. */
+ (NSArray<__kindof NSLayoutConstraint *> *)constraintsWithVisualFormat:(NSString *)format
	options:(NSLayoutFormatOptions)opts
	metrics:(nullable NSDictionary<NSString *,id> *)metrics
	views:(nullable NSDictionary<NSString *, id> *)views
	identifier:(NSString *)identifier DEPRECATED_ATTRIBUTE;

@end

/**
 * A dictionary built from UIEdgeInsets suitable for AutoLayout metrics.
 * The dictionary will have 4 values under the keys named "<prefix>Top", "<prefix>Left", "<prefix>Bottom", "<prefix>Right".
 */
extern NSDictionary<NSString *, NSNumber *> *MMMDictionaryFromUIEdgeInsets(NSString *prefix, UIEdgeInsets insets);


/**
 * A container which lays out its subviews in certain direction one after another using fixed spacing between them.
 * It also aligns all the items along the layout line according to the given alignment settings.
 * Note that you must use setSubviews: method instead of feeding them one by one via `addSubview:`.
 * This is kind of a `UIStackView` that we understand the internals of.
 */
@interface MMMStackContainer : UIView

/** Sets subviews to be laid out. Previously set subviews will be removed from this container first. */
- (void)setSubviews:(NSArray<UIView *> *)subviews;

/** 
 * Insets define the padding around all the subviews.
 * Alignment influences horizontal constraints added for the subviews.
 * Spacing is the fixed distance to set between items.
 */
- (id)initWithDirection:(MMMLayoutDirection)direction
	insets:(UIEdgeInsets)insets
	alignment:(MMMLayoutAlignment)alignment
	spacing:(CGFloat)spacing NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

/**
 * Vertical version of MMMStackContainer.
 */
@interface MMMVerticalStackContainer : MMMStackContainer

- (id)initWithInsets:(UIEdgeInsets)insets
	alignment:(MMMLayoutHorizontalAlignment)alignment
	spacing:(CGFloat)spacing NS_DESIGNATED_INITIALIZER;

- (id)initWithDirection:(MMMLayoutDirection)direction
	insets:(UIEdgeInsets)insets
	alignment:(MMMLayoutAlignment)alignment
	spacing:(CGFloat)spacing NS_UNAVAILABLE;

@end

/** 
 * Horizontal version of MMMStackContainer. 
 */
@interface MMMHorizontalStackContainer : MMMStackContainer

- (id)initWithInsets:(UIEdgeInsets)insets
	alignment:(MMMLayoutVerticalAlignment)alignment
	spacing:(CGFloat)spacing NS_DESIGNATED_INITIALIZER;

- (id)initWithDirection:(MMMLayoutDirection)direction
	insets:(UIEdgeInsets)insets
	alignment:(MMMLayoutAlignment)alignment
	spacing:(CGFloat)spacing NS_UNAVAILABLE;

@end

/**
 * Wraps a view that uses Auto Layout into a manual layout view providing sizeThatFits: for the outside world.
 * Can be handy with old APIs that do not fully support Auto Layout.
 */
@interface MMMAutoLayoutIsolator : UIView

/** The view being wrapped. */
@property (nonatomic, readonly) UIView *view;

- (id)initWithView:(UIView *)view NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

/**
 * Wraps a view padding it from all the sides.
 */
@interface MMMPaddedView : UIView

/** The view being wrapped. */
@property (nonatomic, readonly) UIView *view;

@property (nonatomic, readonly) UIEdgeInsets insets;

- (id)initWithView:(UIView *)view insets:(UIEdgeInsets)insets NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
