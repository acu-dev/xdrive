//
//  XService.h
//  xDrive
//
//  Created by Chris Gibbs on 7/1/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//


#import "AccountViewController.h"
#import "XServiceLocal.h"
#import "XServiceRemote.h"
#import "XServer.h"


@interface XService : NSObject

@property (nonatomic, weak) UIViewController *rootViewController;
	// Top level view controller. Gets messages about server status

+ (XService *)sharedXService;
	// One XService to rule them all

- (XServer *)activeServer;
	// Accessor for the server object saved in db (nil if none saved)

- (void)validateActiveServer;
	// Sends request for the saved server's version info

- (void)validateUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host withViewController:(AccountViewController *)viewController;
	// Saves user/pass as a temporary credential and sends request for the server's version info







- (void)saveServerWithDetails:(NSDictionary *)details;

// Server/account validation
//- (void)validateAccountDetails:(NSDictionary *)details withViewController:(AccountViewController *)viewController;

// Directory entries
- (XDirectory *)directoryWithPath:(NSString *)path;

@end












//
// Logging Macro
//
#define X_SVC_DEBUG
#ifdef X_SVC_DEBUG
#	define XSvcLog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#	define XSvcLog(...)
#endif