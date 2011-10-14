//
//  AccountManager.h
//  xDrive
//
//  Created by Chris Gibbs on 10/14/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

@protocol ValidateAccountDelegate;



@interface AccountManager : NSObject

+ (AccountManager *)validateAccountDetails:(NSDictionary *)details withDelegate:(id<ValidateAccountDelegate>)delegate;
	// Saves user/pass as a temporary credential and sends request for the server's version info.

- (void)validateServerURL:(NSString *)url withCredential:(NSURLCredential *)credential delegate:(id<ValidateAccountDelegate>)delegate;
	// Uses passed credential to request the server's version info at passed url.

@end



@protocol ValidateAccountDelegate <NSObject>

- (void)validateAccountStatusUpdate:(NSString *)status;
	// Allows the view to update with the current status

- (void)validateAccountFailedWithError:(NSError *)error;
	// Problem getting the server info

- (void)validateAccountFinishedWithSuccess;
	// Server info has been successfully validated

@end