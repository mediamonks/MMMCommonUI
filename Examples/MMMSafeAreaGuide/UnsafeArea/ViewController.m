//
// Demo of iOS layout loop bug involving `safeAreaLayoutGuide` and transforms.
// Copyright (C) 2020, MediaMonks.
//

#import "ViewController.h"

// Set to 1 to see the layout loop with safeAreaLayoutGuide.
#define DEMO_LAYOUT_LOOP 0

#if !DEMO_LAYOUT_LOOP
@import MMMCommonUI;
#endif

@interface UnsafeAreaView: UIView
@end

@implementation UnsafeAreaView {
	UIView *_button;
}

- (id)init {

	if (self = [super initWithFrame:CGRectZero]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.backgroundColor = [UIColor blueColor];

		_button = [[UIView alloc] initWithFrame:CGRectZero];
		_button.translatesAutoresizingMaskIntoConstraints = NO;
		_button.backgroundColor = [UIColor redColor];
		[self addSubview:_button];

		NSDictionary *views = NSDictionaryOfVariableBindings(_button);

		// Exact numbers in the horizontal contraint are not important.
		[NSLayoutConstraint activateConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"H:|-(10)-[_button(==150)]-(10)-|"
			options:0 metrics:nil views:views
		]];

		[NSLayoutConstraint activateConstraints:[NSLayoutConstraint
			constraintsWithVisualFormat:@"V:|-(10)-[_button(==150)]"
			options:0 metrics:nil views:views
		]];
		#if DEMO_LAYOUT_LOOP
		[NSLayoutConstraint activateConstraints:@[[NSLayoutConstraint
			constraintWithItem:_button attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			// Use regular safeAreaLayoutGuide to see the bug.
			toItem:self.safeAreaLayoutGuide attribute:NSLayoutAttributeBottom
			multiplier:1 constant:-10
		]]];
		#else
		// This is to verify that mmm_constraintsWithVisualFormat uses mmm_safeAreaLayoutGuide.
		[NSLayoutConstraint activateConstraints:[NSLayoutConstraint
			mmm_constraintsWithVisualFormat:@"V:[_button]-<|"
			options:0 metrics:nil views:views
		]];
		#endif
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	// Follow in the console that it's called indefinitely with height and safeAreaInsets.bottom oscillating.
	NSLog(@"height: %f, safeAreaInsets.bottom: %f", self.frame.size.height, self.safeAreaInsets.bottom);
}

@end

//
//
//
@interface ViewController ()
@end

@implementation ViewController {
	UnsafeAreaView *_unsafeAreaView;
	CGFloat _scale;
	NSTimer *_timer;
}

- (void)viewDidLoad {

	[super viewDidLoad];

	self.view.backgroundColor = [UIColor whiteColor];

	_unsafeAreaView = [[UnsafeAreaView alloc] init];
	[self.view addSubview:_unsafeAreaView];

	NSDictionary *views = NSDictionaryOfVariableBindings(_unsafeAreaView);

	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint
		constraintsWithVisualFormat:@"H:|-(>=10)-[_unsafeAreaView]-(>=10)-|"
	 	options:0 metrics:nil views:views
	]];
	[NSLayoutConstraint activateConstraints:@[[NSLayoutConstraint
		constraintWithItem:_unsafeAreaView attribute:NSLayoutAttributeCenterX
		relatedBy:NSLayoutRelationEqual
		toItem:self.view attribute:NSLayoutAttributeCenterX
		multiplier:1 constant:0
	]]];

	// Again, only vertical ones are important in this demo.
	[NSLayoutConstraint activateConstraints:[NSLayoutConstraint
		constraintsWithVisualFormat:@"V:[_unsafeAreaView]-0-|"
	 	options:0 metrics:nil views:views
	]];

	#if DEMO_LAYOUT_LOOP

	// Slightly delay applying the fatal transform, so the initial layout is visible.
	[self performSelector:@selector(doUnsafeAreaInsets) withObject:nil afterDelay:1];

	#else

	// This tries to apply different scales.
	// Can be used to check our workaround or to find the scale leading to the loop.

	_scale = 1;

	_timer = [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
		_scale = _scale * 0.999;
		_unsafeAreaView.transform = CGAffineTransformMakeScale(1, _scale);
		[self.view setNeedsLayout];
		NSLog(@"scale: %f", _scale);
	}];

	#endif
}

- (void)doUnsafeAreaInsets {

	// Not every number causes the loop, e.g. 0.9 would be safe.
	_unsafeAreaView.transform = CGAffineTransformMakeScale(1, 0.968491);

	// Don't have to mark it as needing layout, changing device orientation would kick the loop as well.
	[self.view setNeedsLayout];
}

@end
