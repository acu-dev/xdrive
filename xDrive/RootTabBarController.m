//
//  RootTabBarController.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "RootTabBarController.h"
#import "DirectoryNavigationController.h"
#import "XService.h"
#import "XDefaultPath.h"
#import "XDriveConfig.h"



@interface RootTabBarController()
- (void)initTabItems;
@end


@implementation RootTabBarController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self initTabItems];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)initTabItems
{
	NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
	NSString *storyboardName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"MainStoryboard_iPhone" : @"MainStoryboard_iPad";
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
	
	// Create nav controller for each default path
	for (XDefaultPath *defaultPath in [[XService sharedXService] activeServer].defaultPaths)
	{
		DirectoryNavigationController *navController = [storyboard instantiateViewControllerWithIdentifier:@"directoryNav"];
		navController.tabBarItem.image = [UIImage imageWithContentsOfFile:defaultPath.icon];
		XDrvDebug(@"Setting tab bar item icon to %@", defaultPath.icon);
		[navController setRootPath:defaultPath.path];
		[navController setTitle:defaultPath.name];
		[viewControllers addObject:navController];
	}
	
	// Root browser
	//DirectoryNavigationController *rootBrowser = [storyboard instantiateViewControllerWithIdentifier:@"directoryNav"];
	//rootBrowser.tabBarItem.image = [UIImage imageNamed:@"eye.png"];
	//[rootBrowser setRootPath:@"/"];
	//[viewControllers addObject:rootBrowser];
	
	// Settings
	UINavigationController *settingsNavController = [storyboard instantiateViewControllerWithIdentifier:@"settingsNav"];
	settingsNavController.tabBarItem.image = [UIImage imageNamed:@"gear.png"];
	[viewControllers addObject:settingsNavController];
	
	// Recent
	UINavigationController *recentNavController = [storyboard instantiateViewControllerWithIdentifier:@"recentNav"];
	recentNavController.tabBarItem.image = [UIImage imageNamed:@"clock.png"];
	[viewControllers addObject:recentNavController];
	
	// Init tab items
	self.viewControllers = viewControllers;
}

@end
