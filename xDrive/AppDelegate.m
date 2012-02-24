//
//  AppDelegate.m
//  xDrive
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "AppDelegate.h"
#import "XDriveConfig.h"
#import "XService.h"
#import "SetupController.h"
#import "UIStoryboard+Xdrive.h"
#import "VersionController.h"


@interface AppDelegate ()

@property (nonatomic, strong) SetupController *setupController;
@property (nonatomic, strong) VersionController *versionController;

- (void)cleanupSetup;

@end




@implementation AppDelegate

@synthesize window;
@synthesize setupController;
@synthesize versionController;



#pragma mark - Application

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Implement iPad specific stuff
	/*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	 UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
	 UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
	 splitViewController.delegate = (id)navigationController.topViewController;
	 }*/
	
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	
	
	// Get root view controller
	if (![[XService sharedXService] activeServer])
	{
		// No server configured so make setup the root view controller
		XDrvDebug(@"Loading initial setup");
		setupController = [[SetupController alloc] init];
		window.rootViewController = [setupController viewController];
	}
	else
	{
		// Load storyboard's initial view controller
		window.rootViewController = [[UIStoryboard mainStoryboard] instantiateInitialViewController];
	}

	// Display
	[window makeKeyAndVisible];
	
	// Create version controller
	versionController = [[VersionController alloc] init];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
	
	[versionController checkVersion];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */

}



#pragma mark - Setup cleanup

- (void)tabBarControllerDidAppear:(UITabBarController *)tabBarController
{
	self.window.rootViewController = tabBarController;
	[self performSelector:@selector(cleanupSetup) withObject:nil afterDelay:1.0];
}

- (void)cleanupSetup
{
	if (setupController)
	{
		XDrvDebug(@"Removing setup controller");
		self.setupController = nil;
	}
}



#pragma mark - Logout and setup

- (void)logoutAndBeginSetup
{
	setupController = [[SetupController alloc] init];
	[setupController resetBeforeSetup];
	[window.rootViewController presentViewController:[setupController viewController] animated:YES completion:^{
		self.window.rootViewController = [setupController viewController];
	}];
}



@end














