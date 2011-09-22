//
//  XDefaultPathController.h
//  xDrive
//
//  Created by Chris Gibbs on 9/22/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"



@interface XDefaultPathController : NSObject

- (void)fetchDefaultPaths:(NSArray *)defaultPaths withDelegate:(id<ServerStatusDelegate>)delegate;
	// Fires off requests to get the directory contentes and icon file for each default path.

@end
