//
//  AccountManager.m
//  xDrive
//
//  Created by Chris Gibbs on 10/14/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "AccountManager.h"
#import "XService.h"



@interface AccountManager() <XServiceRemoteDelegate>

@property (nonatomic, weak) id<ValidateAccountDelegate> validateAccountDelegate;
	// Delegate to send server validation results back to

@end




@implementation AccountManager

@synthesize validateAccountDelegate;



+ (AccountManager *)validateAccountDetails:(NSDictionary *)details withDelegate:(id<ValidateAccountDelegate>)delegate
{
	NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:[details objectForKey:@"username"] 
															   password:[details objectForKey:@"password"] 
															persistence:NSURLCredentialPersistenceNone];
	AccountManager *manager = [[AccountManager alloc] init];
	[manager validateServerURL:[details objectForKey:@"server"] withCredential:credential delegate:delegate];
	return manager;
}

- (void)validateServerURL:(NSString *)url withCredential:(NSURLCredential *)credential delegate:(id<ValidateAccountDelegate>)delegate
{
	validateAccountDelegate = delegate;
	[[XService sharedXService].remoteService fetchServerInfoAtHost:url withDelegate:self];
}

@end
