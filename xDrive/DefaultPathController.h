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

///-------------------
/// @name Initializing
///-------------------

/**
 Designated initializer.
 
 @param setupController The setup controller to receive notifications.
 */
- (id)initWithSetupController:(SetupController *)setupController;

///-----------------------------------------
/// @name Getting the Server's Default Paths
///-----------------------------------------

/**
 Gets a list of default paths that have been configured on the specified server and creates local `XDefaultPath` and `XDirectory` objects for them.
 
 @discussion This acts as an authentication validation because the default paths service is protected. If everything is setup successfully `defaultPathsValidated` will be called on the `SetupController`. 
 
 @param server The XServer object to fetch default paths from.
 */
- (void)fetchDefaultPathsForServer:(XServer *)server;

///-------------------------------------
/// @name Initializing the Default Paths
///-------------------------------------

/**
 Begins updating directory contents for each default path on the server.
 
 @discussion If the default path has icons configured they will be downloaded and associated with the default path as well.
 */
- (void)initializeDefaultPaths;

@end
