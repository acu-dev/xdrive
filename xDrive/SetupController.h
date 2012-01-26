//
//  SetupController.h
//  xDrive
//
//  Created by Chris Gibbs on 1/20/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SetupController : NSObject

- (UIViewController *)viewController;
	// Initializes the setup view controller for displaying on initial app launch

- (void)setupWithUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host;
	// Starts validating the user/pass/host provided

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

@end
