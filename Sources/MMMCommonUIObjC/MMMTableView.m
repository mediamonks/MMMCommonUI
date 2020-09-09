//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMTableView.h"

@implementation MMMTableView {
	MMMScrollViewShadows *_shadows;
}

- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings style:(UITableViewStyle)style {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, 320, 400) style:style]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;

		_shadows = [[MMMScrollViewShadows alloc] initWithScrollView:self settings:settings];
	}

	return self;
}

- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings {
	return [self initWithSettings:settings style:UITableViewStylePlain];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[_shadows layoutSubviews];
}

@end
