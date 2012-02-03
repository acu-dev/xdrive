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
#import "AppDelegate.h"



@interface RootTabBarController()
- (void)initTabItems;
- (NSArray *)orderedViewControllers:(NSArray *)viewControllers;
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

- (void)viewDidAppear:(BOOL)animated
{
	// Tell app delegate we've appeared so we can become root view controller and setup controllers can be cleaned up
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] tabBarControllerDidAppear:self];
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
	
	// Recent
	UINavigationController *recentNavController = [storyboard instantiateViewControllerWithIdentifier:@"recentNav"];
	recentNavController.tabBarItem.image = [UIImage imageNamed:@"clock.png"];
	[viewControllers addObject:recentNavController];
	
	// Settings
	UINavigationController *settingsNavController = [storyboard instantiateViewControllerWithIdentifier:@"settingsNav"];
	settingsNavController.tabBarItem.image = [UIImage imageNamed:@"gear.png"];
	[viewControllers addObject:settingsNavController];
	
	// Init tab items
	self.viewControllers = [self orderedViewControllers:viewControllers];
}

- (NSArray *)orderedViewControllers:(NSArray *)viewControllers
{
	NSArray *savedOrder = [XDriveConfig getSavedTabItemOrder];
	NSMutableArray *orderedViewControllers = [NSMutableArray arrayWithCapacity:[savedOrder count]];
	
	for (int i = 0; i < [savedOrder count]; i++)
	{
		for (UIViewController *viewController in viewControllers)
		{
			if ([viewController.title isEqualToString:[savedOrder objectAtIndex:i]])
			{
				[orderedViewControllers addObject:viewController];
			}
		}
	}
	return orderedViewControllers;
}


@end







