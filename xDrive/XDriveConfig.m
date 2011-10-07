//
//  XDriveConfig.m
//  xDrive
//
//  Created by Chris Gibbs on 10/7/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XDriveConfig.h"

@implementation XDriveConfig

+ (BOOL)shouldResetApp
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:@"reset_app"];
}

+ (void)setAccountUsername:(NSString *)username
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:username forKey:@"account_username"];
}

+ (void)setAccountServer:(NSString *)server
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:server forKey:@"account_server"];
}

@end