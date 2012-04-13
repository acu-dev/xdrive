//
//  AppDelegate.h
//  xDrive
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)rootViewControllerDidAppear:(UIViewController *)viewController;
	// Ensures that the root view controller gets set as the window's root view controller (after setup)

- (void)logoutAndBeginSetup;
	// Resets the database and launches setup controller

@end
