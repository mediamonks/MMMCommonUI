//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/** 
 * This is to group a few simple layout helpers.
 */
@interface MMMLayoutUtils : NSObject

/** 
 * A rect with the given size positioned inside of the target rect in such a way that anchor points of both rects align.
 *
 * Anchor points are given relative to the sizes of the corresponding rects, similar to CALayer's `anchorPoint`
 * property. For example, `CGPointMake(0.5, 0.5)` represents a center of any rect; `CGPointMake(1, 0.5)` means
 * the center point of the right vertical edge.
 *
 * Note that the origin of the rect returned is rounded to the nearest pixels (not points!).
 *
 * See `rectWithSize:inRect:contentMode:` for a shortcut supporting UIViewContentMode.
 */
+ (CGRect)rectWithSize:(CGSize)size anchor:(CGPoint)anchor withinRect:(CGRect)targetRect anchor:(CGPoint)targetAnchor
	NS_SWIFT_NAME(rect(withSize:anchor:withinRect:anchor:));

/** 
 * A shortcut for the above method with anchors being the same for both source and target rect.
 * (This way the resulting rect will be always inside of the target one, assuming anchors are within [0; 1] range.)
 */
+ (CGRect)rectWithSize:(CGSize)size withinRect:(CGRect)targetRect anchor:(CGPoint)anchor
	NS_SWIFT_NAME(rect(withSize:withinRect:anchor:));

/** 
 * A frame for the `sourceRect` positioned within the `targetRect` according to standard `UIViewContentMode` flags
 * related to the layout (i.e. all except `UIViewContentModeRedraw`).
 *
 * Note that the origin of the resulting rectangle is always rounded to the nearest pixel.
 */
+ (CGRect)rectWithSize:(CGSize)size withinRect:(CGRect)targetRect contentMode:(UIViewContentMode)contentMode
	NS_SWIFT_NAME(rect(withSize:withinRect:contentMode:));

/** 
 * A frame of the given size with its center at the specified point (assuming the center is defined by the given anchor
 * point).
 *
 * Note that the origin of the resulting rectangle is rounded to the nearest pixel boundary.
 */
+ (CGRect)rectWithSize:(CGSize)size atPoint:(CGPoint)center anchor:(CGPoint)anchor
	NS_SWIFT_NAME(rect(withSize:atPoint:anchor:));

/** Same as rectWithSize:center:anchor: with anchor set to (0.5, 0.5). */
+ (CGRect)rectWithSize:(CGSize)size center:(CGPoint)center
	NS_SWIFT_NAME(rect(withSize:center:));

@end

/** 
 * Suppose you need to contrain a view so its center divides its container in certain ratio different from 1:1
 * (e.g. golden section):
 *
 *  ┌─────────┐ ◆
 *  │         │ │
 *  │         │ │ a
 *  │┌───────┐│ │
 * ─│┼ ─ ─ ─ ┼│─◆   ratio = a / b
 *  │└───────┘│ │
 *  │         │ │
 *  │         │ │
 *  │         │ │ b
 *  │         │ │
 *  │         │ │
 *  │         │ │
 *  └─────────┘ ◆
 *
 * You cannot put this ratio directly into the `multiplier` parameter of the corresponding NSLayoutConstraints relating
 * the centers of the views, because the `multiplier` would be the ratio between the distance to the center
 * of the view (`h`) and the distance to the center of the container (`H`) instead:
 *
 *   ◆ ┌─────────┐ ◆
 *   │ │         │ │
 *   │ │         │ │ a = h
 * H │ │┌───────┐│ │
 *   │ │├ ─ ─ ─ ┼│─◆   multiplier = h / H
 *   │ │└───────┘│ │   ratio = a / b = h / (2 * H - h)
 *   ◆─│─ ─ ─ ─ ─│ │
 *     │         │ │
 *     │         │ │ b = 2 * H - h
 *     │         │ │
 *     │         │ │
 *     │         │ │
 *     └─────────┘ ◆
 *
 * I.e. the `multiplier` is h / H (assuming the view is the first in the definition of the constraint),
 * but the ratio we are interested would be h / (2 * H - h) if expressed in the distances to centers.
 *
 * If you have a desired ratio and want to get a `multiplier`, which when applied, results in the layout dividing
 * the container in this ratio, then you can use this function as shortcut.
 *
 * Detailed calculations:
 * ratio = h / (2 * H - h)  ==>  2 * H * ratio - h * ratio = h  ==>  2 * H * ratio / h - ratio = 1
 * ==>  1 + ratio = 2 * H * ratio / h  ==>  (1 + ratio) / (2 * ratio) = H / h
 * where H / h is the inverse of our `multiplier`, so the actual multiplier is (2 * ratio) / (1 + ratio).
 */
static
NS_SWIFT_NAME(MMMLayoutUtils.centerMultiplier(forRatio:))
inline CGFloat MMMCenterMultiplierForRatio(CGFloat ratio) {
	return (2 * ratio) / (1 + ratio);
}

/** Golden ratio constant. */
extern CGFloat const MMMGolden NS_SWIFT_NAME(MMMLayoutUtils.golden);

/** 1 divided by golden ratio. */
extern CGFloat const MMMInverseGolden NS_SWIFT_NAME(MMMLayoutUtils.inverseGolden);

#define MMM_GOLDEN (MMMGolden)
#define MMM_INVERSE_GOLDEN (MMMInverseGolden)

NS_ASSUME_NONNULL_END
