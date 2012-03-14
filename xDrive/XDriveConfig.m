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

+ (NSDictionary *)localStorageOption
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"LocalStorageOption"];
}

+ (void)setLocalStorageOption:(NSDictionary *)option
{
	[[NSUserDefaults standardUserDefaults] setObject:option forKey:@"LocalStorageOption"];
}

+ (NSArray *)localStorageOptions
{
	return [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LocalStorageOptions" ofType:@"plist"]] objectForKey:@"options"];
}

+ (NSDictionary *)defaultLocalStorageOption
{
	NSDictionary *localStorageOptions = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LocalStorageOptions" ofType:@"plist"]];
	return [[localStorageOptions objectForKey:@"options"] objectAtIndex:[[localStorageOptions objectForKey:@"defaultOption"] integerValue]];
}

+ (long long)totalCachedBytes
{
	NSNumber *cachedBytes = [[NSUserDefaults standardUserDefaults] objectForKey:@"TotalCachedBytes"];
	return (cachedBytes) ? [cachedBytes longLongValue] : 0;
}

+ (void)setTotalCachedBytes:(long long)cachedBytes
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:cachedBytes] forKey:@"TotalCachedBytes"];
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
	if (!server) server = [XService sharedXService].localService.server;
	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:server.hostname
																				  port:[server.port integerValue]
																			  protocol:server.protocol
																				 realm:server.hostname
																  authenticationMethod:@"NSURLAuthenticationMethodDefault"];
	return protectionSpace;
}


@end