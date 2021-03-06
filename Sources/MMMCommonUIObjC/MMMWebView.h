//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "MMMScrollViewShadows.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Web view supporting top & bottom shadows.
 */
@interface MMMWebView : WKWebView

- (instancetype)initWithSettings:(MMMScrollViewShadowsSettings *)settings;
- (instancetype)initWithSettings:(MMMScrollViewShadowsSettings *)settings configuration:(WKWebViewConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
