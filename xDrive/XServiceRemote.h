//
//  XServiceRemote.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServer.h"

typedef void (^XServiceCompletionBlock)(id result);
typedef void (^XServiceFailedBlock)(NSError *error);
typedef void (^XServiceUpdateBlock)(float percentDownloaded);
typedef NSURLCredential * (^XServiceAuthenticationChallengeBlock)(NSURLAuthenticationChallenge *challenge);

@interface XServiceRemote : NSObject

/**
 A block to be executed when connections fail.
 */
@property (nonatomic, copy) XServiceFailedBlock failureBlock;

/**
 A block to evaluate and respond to authentication challenges.
 */
@property (nonatomic, copy) XServiceAuthenticationChallengeBlock authenticationChallengeBlock;

///---------------------
/// @name Initialization
///---------------------

/**
 Initializes the remote service and sets the server object to use.
 
 @param server The server object to build URLs from
 */
- (id)initWithServer:(XServer *)server;

///----------------------------
/// @name Getting Entry Details
///----------------------------

- (void)fetchDefaultPathsWithCompletionBlock:(XServiceCompletionBlock)completionBlock;
- (void)fetchEntryDetailsAtPath:(NSString *)path withCompletionBlock:(XServiceCompletionBlock)completionBlock;

///------------------------
/// @name Downloading Files
///------------------------

- (void)downloadFileAtPath:(NSString *)path ifModifiedSinceCachedDate:(NSDate *)cachedDate
		   withUpdateBlock:(XServiceUpdateBlock)updateBlock
		   completionBlock:(XServiceCompletionBlock)completionBlock;

@end




