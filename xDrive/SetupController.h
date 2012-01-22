//
//  SetupController.h
//  xDrive
//
//  Created by Chris Gibbs on 1/20/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SetupController : NSObject

@property (strong, nonatomic) UIViewController *viewController;
	// View controller to provide user/host/pass

- (void)setupWithUsername:(NSString *)username password:(NSString *)password forHost:(NSString *)host;
	// Starts validating the user/pass/host provided

@end
