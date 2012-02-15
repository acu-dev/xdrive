//
//  XDriveConfig.m
//  xDrive
//
//  Created by Chris Gibbs on 10/7/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XDriveConfig.h"
#import "XService.h"



@implementation XDriveConfig


#pragma mark - App Info

+ (NSString *)appVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (NSString *)appName
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

+ (NSArray *)supportedServiceVersions
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SupportedServiceVersions"];
}



#pragma mark - Settings

+ (NSInteger)localStorageAmount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"LocalStorageAmount"];
}

+ (void)setLocalStorageAmount:(NSInteger)amount
{
	[[NSUserDefaults standardUserDefaults] setInteger:amount forKey:@"LocalStorageAmount"];
}



#pragma mark - Tab Item Order

+ (void)saveTabItemOrder:(NSArray *)order
{
	[[NSUserDefaults standardUserDefaults] setObject:order forKey:@"savedTabOrder"];
}

+ (NSArray *)getSavedTabItemOrder
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"savedTabOrder"];
}



#pragma mark - Utils

+ (NSURLProtectionSpace *)protectionSpaceForServer:(XServer *)server
{
	if (!server) server = [XService sharedXService].activeServer;
	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:server.hostname
																				  port:[server.port integerValue]
																			  protocol:server.protocol
																				 realm:server.hostname
																  authenticationMethod:@"NSURLAuthenticationMethodDefault"];
	return protectionSpace;
}


@end