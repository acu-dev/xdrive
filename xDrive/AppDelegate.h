//
//  AppDelegate.h
//  xDrive
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)tabBarControllerDidAppear:(UITabBarController *)tabBarController;
	// Ensures that the tab bar controller gets set as the root view controller (after setup)

- (void)logoutAndBeginSetup;
	// Resets the database and launches setup controller

@end
