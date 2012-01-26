//
//  XDefaultPathController.h
//  xDrive
//
//  Created by Chris Gibbs on 9/22/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"
#import "SetupController.h"


@interface DefaultPathController : NSObject

- (id)initWithController:(SetupController *)controller;
	// Inits the default path controller with a reference to the master setup controller

- (void)fetchDefaultPathsForServer:(XServer *)server;
	// Gets a list of default paths that have been configured on the server

- (void)initializeDefaultPaths;
	// Begins fetching directory contents for each default path on the server

@end
