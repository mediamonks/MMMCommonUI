//
// MMMCommonUI. Part of MMMTemple.
// Copyright (c) 2023 MediaMonks. All rights reserved.
// 

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 * Auto Layout does not support constraints against groups of items, so this is for the cases a normal UIView is
 * typically used as a container for such a group.
 * Unlike UIView we have translatesAutoresizingMaskIntoConstraints set to NO already.
 * Also `MMMContainerView` does not intercept touches but subviews still do.
 */
@interface MMMContainerView : UIView

- (nonnull id)init NS_DESIGNATED_INITIALIZER;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
