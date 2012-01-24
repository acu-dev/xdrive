//
//  XDefaultPathController.h
//  xDrive
//
//  Created by Chris Gibbs on 9/22/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"
#import "SetupViewController.h"


@interface DefaultPathController : NSObject

- (id)initWithServer:(XServer *)server;
	// Init with a server to save default path data to

- (void)fetchDefaultPathsWithViewController:(SetupViewController *)viewController;
	// Gets a list of default paths configured on the server

@end
