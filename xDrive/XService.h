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
@protocol ServerStatusDelegate;



@interface XService : NSObject


@property (nonatomic, strong, readonly) XServiceLocal *localService;
	// A service object to handle reading/writing objects to local db

@property (nonatomic, strong, readonly) XServiceRemote *remoteService;
	// A service object to handle fetching/pushing data to the server

@property (nonatomic, weak) id<ServerStatusDelegate> serverStatusDelegate;
	// Delegate to send server validation results back to

+ (XService *)sharedXService;
	// One XService to rule them all

+ (NSString *)appVersion;
	// Current version of the app as defined in the Info plist

+ (NSString *)appName;
	// Display name of the app as defined in the Info plist

- (XServer *)activeServer;
	// Accessor for the server object saved in db (nil if none saved)

- (void)validateUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host withDelegate:(id<ServerStatusDelegate>)delegate;
	// Saves user/pass as a temporary credential and sends request for the server's version info

- (void)validateServerWithDelegate:(id<ServerStatusDelegate>)delegate;
	// Sends request for the saved server's info




// Directory entries
- (XDirectory *)directoryWithPath:(NSString *)path;

@end




typedef enum _ServerStatus{
	ServerIsOffline,
	ServerIsOnline,
	ServerIsIncompatible
} ServerStatus;

@protocol ServerStatusDelegate <NSObject>

- (void)validateServerStatusUpdate:(NSString *)status;
	// Allows the view to update with the current status

- (void)validateServerFailedWithError:(NSError *)error;
	// Problem getting the server info

- (void)validateServerFinishedWithSuccess;
	// Server info has been successfully validated

@optional

- (void)serverStatusChanged:(ServerStatus)serverStatus;

@end