//
//  VersionController.h
//  xDrive
//
//  Created by Chris Gibbs on 2/24/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XService.h"

@interface VersionController : NSObject //<XServiceRemoteDelegate>

- (void)checkVersion;
	// Starts a fetch to get the latest version

@end
