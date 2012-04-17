//
//  SetupFinishedSegue.m
//  xDrive
//
//  Created by Chris Gibbs on 4/17/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "SetupFinishedSegue.h"
#import "AppDelegate.h"

@implementation SetupFinishedSegue

- (void)perform
{
	UIView *sourceView = ((UIViewController *)self.sourceViewController).view;
	UISplitViewController *destinationViewController = (UISplitViewController *)self.destinationViewController;
	UIViewController *detailViewController = [[destinationViewController.viewControllers lastObject] topViewController];
	destinationViewController.delegate = (id)detailViewController;
	
	[UIView transitionFromView:sourceView toView:destinationViewController.view duration:0.8 options:UIViewAnimationOptionTransitionCrossDissolve completion:NULL];
}

@end
