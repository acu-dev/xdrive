//
//  SplitViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 4/2/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "SplitViewController.h"
#import "XDriveConfig.h"
#import "AppDelegate.h"

@interface SplitViewController ()

@end

@implementation SplitViewController

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] rootViewControllerDidAppear:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
