//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MMMObservables;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MMMKeyboardState) {

	/** 
	 * We don't know for sure if the keyboard is hidden or not.
	 * There is no way to read this when the MMMKeyboard is created, so ensure you have an instance early enough. 
	 */
	MMMKeyboardStateUnknown = 0,

	/** The keyboard is hidden or is being hid now. */
	MMMKeyboardStateHidden,

	/** The keyboard is visible now or is being shown now. */
	MMMKeyboardStateVisible
};

@protocol MMMKeyboardObserver;

/** 
 * An object knowing the state and position of the keyboard and helping with layout of views
 * that should not be overlapped by it.
 */
@interface MMMKeyboard : NSObject

/** 
 * Normal shared and lazily initialized instance.
 * It's benefitial to force creation of one early on startup so the state/position is known asap. 
 */
+ (instancetype)shared;

/** The current state of the keyboard. */
@property (nonatomic, readonly) MMMKeyboardState state;

/** 
 * In case the keyboard is visible, then bounds of the largest top part of the view not covered by the keyboard;
 * in case it's hidden, then unchanged bounds of the view.
 *
 * Note that in case the view is covered by the keyboard completely, then the bounds of the view with the height
 * set to zero are returned.
 */
- (CGRect)boundsNotCoveredByKeyboardForView:(UIView *)view;

/** 
 * How the bounds rect of the given view should be inset so it is not covered by the keyboard.
 * This can be handy to use with a scroll view, for example, to adjust its insets instead of a frame.
 */
- (UIEdgeInsets)insetsForBoundsNotCoveredByKeyboardForView:(UIView *)view;

/** In case the keyboard is visible, then the height of the part covered by it; 0 when the keyboard is hidden. */
- (CGFloat)heightOfPartCoveredByKeyboardForView:(UIView *)view;

/** Adds an observer and returns a token corresponding to it. The observer is removed when the token is deallocated. */
- (id<MMMObserverToken>)addObserver:(id<MMMKeyboardObserver>)observer;

@end

@protocol MMMKeyboardObserver <NSObject>

/** 
 * Called when the keyboard is about to appear or disappear. 
 * The duration of the animation and a corresponding animation curve can be used to coordinate the animation 
 * of the view listening to state changes.
 *
 * You can use MMMAnimationOptionsFromAnimationCurve() to use the curve parameter where UIViewAnimationOptions
 * are expected.
 *
 * The 'MMMKeyboard#boundsNotCoveredByKeyboardForView:' method should be ready at this point to help with 
 * calculation of the obscured area.
 */
- (void)keyboard:(MMMKeyboard *)keyboard
	willChangeStateWithAnimationDuration:(NSTimeInterval)duration
	curve:(UIViewAnimationCurve)curve;

@end

NS_ASSUME_NONNULL_END
