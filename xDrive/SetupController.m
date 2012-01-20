//
//  SetupController.m
//  xDrive
//
//  Created by Chris Gibbs on 1/20/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "SetupController.h"
#import "XService.h"
#import "XServiceRemote.h"



@interface SetupController() <XServiceRemoteDelegate>

@property (nonatomic, strong) NSURLCredential *validateCredential;
	// Credential used when validating server info.
	
@end




@implementation SetupController

@synthesize validateCredential;



#pragma mark - XServiceRemoteDelegate

- (void)connectionFinishedWithResult:(NSObject *)result
{
	
}

- (void)connectionFailedWithError:(NSError *)error
{
	
}

- (NSURLCredential *)credentialForAuthenticationChallenge
{
	
}

@end
