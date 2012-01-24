//
//  XDefaultPathController.h
//  xDrive
//
//  Created by Chris Gibbs on 9/22/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"



@interface XDefaultPathController : NSObject

- (void)fetchDefaultPathsWithStatusDelegate:(id<ServerStatusDelegate>)delegate;
	// Gets a list of default paths configured on the server

@end
