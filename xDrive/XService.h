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

@property (nonatomic, strong, readonly) XServiceLocal *localService;
// A service object to handle reading/writing objects to local db

@property (nonatomic, strong, readonly) XServiceRemote *remoteService;
// A service object to handle fetching/pushing data to the server

@property (nonatomic, weak) UIViewController *rootViewController;
	// Top level view controller. Gets messages about server status

+ (XService *)sharedXService;
	// One XService to rule them all

+ (NSString *)appVersion;
	// Current version of the app as defined in the Info plist

+ (NSString *)appName;
	// Display name of the app as defined in the Info plist9

- (XServer *)activeServer;
	// Accessor for the server object saved in db (nil if none saved)

- (void)validateUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host withViewController:(AccountViewController *)viewController;
	// Saves user/pass as a temporary credential and sends request for the server's version info

- (void)checkServerVersion;
	// Sends request for the saved server's version info




// Directory entries
- (XDirectory *)directoryWithPath:(NSString *)path;

@end