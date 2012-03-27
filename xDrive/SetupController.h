//
//  SetupController.h
//  xDrive
//
//  Created by Chris Gibbs on 1/20/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XServer.h"


typedef enum {
	ServerIsOffline,
	ServerIsOnline,
	ServerIsIncompatible
} ServerStatus;


@interface SetupController : NSObject

/**
 Login view controller.
 */
@property (nonatomic, strong, readonly) UIViewController *viewController;

/**
 Username and password to use for authenticating with xservice.
 */
@property (nonatomic, strong, readonly) NSString *validateUser, *validatePass;

/**
 Server object to validate and store if successful.
 */
@property (nonatomic, strong, readonly) XServer *server;

/**
 Status of the reset process.
 */
@property (nonatomic, assign, readonly) BOOL isResetting;

/**
 Starts validating the user/pass/host provided.
 
 @param username The username to use for authentication.
 @param password The password to use for authentication.
 @param host The host to validate and if successful, setup.
 */
- (void)setupWithUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host;







- (void)defaultPathsStatusUpdate:(NSString *)status;
	// Status update of the default path setup

- (void)defaultPathsFailedWithError:(NSError *)error;
	// Something went wrong while setting up the default paths

- (void)defaultPathsValidated;
	// Called when the list of default paths has been successfully recieved and added
	// to the server object. Attempts to save the managed object context and continue
	// initializing the default paths

- (void)defaultPathsFinished;
	// Default paths have all been initialized successfully

- (void)resetBeforeSetup;
	// Restores the app to original state before running setup

@end
