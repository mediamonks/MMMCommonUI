//
// Demo of iOS layout loop bug involving `safeAreaLayoutGuide` and transforms.
// Copyright (C) 2020, MediaMonks.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate {
	UIWindow *_window;
	ViewController *_viewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_viewController = [[ViewController alloc] init];
	_window.rootViewController = _viewController;
	[_window makeKeyAndVisible];

	return YES;
}

@end
