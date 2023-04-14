//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMLayoutUtils.h"

#if SWIFT_PACKAGE
@import MMMCommonCoreObjC;
#else
@import MMMCommonCore;
#endif

#import "MMMCommonUIMisc.h"
#import <objc/runtime.h>

//
//
//
@implementation MMMLayoutUtils

+ (CGRect)rectWithSize:(CGSize)size anchor:(CGPoint)anchor withinRect:(CGRect)targetRect anchor:(CGPoint)targetAnchor {
	return MMMPixelIntegralRect(CGRectMake(
		targetRect.origin.x + targetRect.size.width * targetAnchor.x - size.width * anchor.x,
		targetRect.origin.y + targetRect.size.height * targetAnchor.y - size.height * anchor.y,
		size.width,
		size.height
	));
}

+ (CGRect)rectWithSize:(CGSize)size withinRect:(CGRect)targetRect anchor:(CGPoint)anchor {
	return MMMPixelIntegralRect(CGRectMake(
		targetRect.origin.x + (targetRect.size.width - size.width) * anchor.x,
		targetRect.origin.y + (targetRect.size.height - size.height) * anchor.y,
		size.width,
		size.height
	));
}

+ (CGRect)rectWithSize:(CGSize)size withinRect:(CGRect)targetRect contentMode:(UIViewContentMode)contentMode {

	switch (contentMode) {

		case UIViewContentModeScaleToFill:
			// Not much sense using this routine with this mode, but well, maybe it's coming from the corresponding property of UIView here
			return targetRect;

		case UIViewContentModeScaleAspectFit:
		case UIViewContentModeScaleAspectFill:
			{
				double scaleX = targetRect.size.width / size.width;
				double scaleY = targetRect.size.height / size.height;
				double scale = (contentMode == UIViewContentModeScaleAspectFit) ? MIN(scaleX, scaleY) : MAX(scaleX, scaleY);
				CGFloat resultWidth = size.width * scale;
				CGFloat resultHeight = size.height * scale;
				return MMMPixelIntegralRect(
					CGRectMake(
						targetRect.origin.x + (targetRect.size.width - resultWidth) * 0.5f,
						targetRect.origin.y + (targetRect.size.height - resultHeight) * 0.5f,
						resultWidth,
						resultHeight
					)
				);
			}

		case UIViewContentModeRedraw:
			NSAssert(NO, @"UIViewContentModeRedraw does not make any sense for %s", sel_getName(_cmd));
			return targetRect;

		case UIViewContentModeCenter:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0.5, 0.5)];

		case UIViewContentModeTop:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0.5, 0)];

		case UIViewContentModeBottom:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0.5, 1)];

		case UIViewContentModeLeft:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0, 0.5)];

		case UIViewContentModeRight:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(1, 0.5)];

		case UIViewContentModeTopLeft:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0, 0)];

		case UIViewContentModeTopRight:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(1, 0)];

		case UIViewContentModeBottomLeft:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0, 1)];

		case UIViewContentModeBottomRight:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(1, 1)];
	}
}

+ (CGRect)rectWithSize:(CGSize)size atPoint:(CGPoint)point anchor:(CGPoint)anchor {
	return MMMPixelIntegralRect(CGRectMake(
		point.x - size.width * anchor.x,
		point.y - size.height * anchor.y,
		size.width,
		size.height
	));
}

+ (CGRect)rectWithSize:(CGSize)size center:(CGPoint)center {
	return [self rectWithSize:size atPoint:center anchor:CGPointMake(.5f, .5f)];
}

@end

CGFloat const MMMGolden = 1.47093999 * 1.10; // 110% adjusted.
CGFloat const MMMInverseGolden = 1 / MMMGolden;
