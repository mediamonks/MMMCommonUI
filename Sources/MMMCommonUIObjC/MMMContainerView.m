//
// Starbucks App.
// Copyright (c) 2023 MediaMonks. All rights reserved.
// 

#import "MMMContainerView.h"

@implementation MMMContainerView

- (id)init {

	if (self = [super initWithFrame:CGRectZero]) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
	}

	return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

	UIView *view = [super hitTest:point withEvent:event];

	if (view == self) {
		return nil;
	} else {
		return view;
	}
}

@end
