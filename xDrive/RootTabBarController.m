//
//  RootTabBarController.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "RootTabBarController.h"
#import "UIStoryboard+Xdrive.h"
#import "DirectoryContentsViewController.h"
#import "XService.h"
#import "XDefaultPath.h"
#import "XDriveConfig.h"
#import "AppDelegate.h"




@interface RootTabBarController()
- (void)initTabItems;
- (NSArray *)orderedViewControllers:(NSArray *)viewControllers;
@end


@implementation RootTabBarController



- (void)awakeFromNib
{
	self.delegate = self;
}



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
	[super viewDidAppear:animated];
	
	// Tell app delegate we've appeared so we can become root view controller and setup controllers can be cleaned up
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] tabBarControllerDidAppear:self];
}

- (void)initTabItems
{
	XDrvDebug(@"Initializing tab items");
	NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
	
	// Create nav controller for each default path
	for (XDefaultPath *defaultPath in [[XService sharedXService].localService server].defaultPaths)
	{
		if (![defaultPath.path isEqualToString:@"/users/cjs00c"]) continue;
		
		DirectoryContentsViewController *viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"directoryContents"];
		viewController.directory = defaultPath.directory;
		viewController.title = defaultPath.name;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
		navController.tabBarItem.image = [UIImage imageWithContentsOfFile:defaultPath.icon];
		navController.title = defaultPath.name;

		[viewControllers addObject:navController];
	}
	
	// Recent
	UINavigationController *recentNavController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"recentNav"];
	recentNavController.tabBarItem.image = [UIImage imageNamed:@"clock.png"];
	[viewControllers addObject:recentNavController];
	
	// Settings
	UINavigationController *settingsNavController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"settingsNav"];
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



#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
	NSMutableArray *saveOrder = [NSMutableArray arrayWithCapacity:[self.viewControllers count]];
	for (UIViewController *viewController in self.viewControllers) {
		[saveOrder addObject:viewController.title];
	}
	
	[XDriveConfig saveTabItemOrder:saveOrder];
}


@end







