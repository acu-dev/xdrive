//
//  XServiceRemote.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServer.h"
@protocol XServiceRemoteDelegate;



@interface XServiceRemote : NSObject

@property (strong, nonatomic) XServer *activeServer;
	// Server info to use when building request URLs

@property (nonatomic, weak) id<XServiceRemoteDelegate> authDelegate;
	// Special delegate to handle authentication challenges instead of the connection's delegate

- (id)initWithServer:(XServer *)server;
	// Saves the server to use for requests and initializes the requests storage

- (void)fetchJSONAtURL:(NSString *)url withTarget:(id)target action:(SEL)action;
- (void)fetchJSONAtURL:(NSString *)url withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Creates the connection and saves the target/action in the requests dictionary
	// to be used when the connection returns.

- (void)fetchInfoAtHost:(NSString *)host withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Gets the server info (version, service paths, etc)

- (void)fetchDefaultPathsForServer:(XServer *)server withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Gets the server's configured default paths.

- (void)fetchDirectoryContentsAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Gets the directory contents for a path


- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action;

- (void)downloadFileAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate;
- (void)downloadFileAtPath:(NSString *)path ifModifiedSinceCachedDate:(NSDate *)cachedDate withDelegate:(id<XServiceRemoteDelegate>)delegate;
- (void)downloadFileAtAbsolutePath:(NSString *)path ifModifiedSinceCachedDate:(NSDate *)cachedDate withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Downloads a file at given url path and notifies delegate on events


@end



@protocol XServiceRemoteDelegate <NSObject>

- (void)connectionFinishedWithResult:(NSObject *)result;
    // Result of the remote connection

@optional

- (void)connectionFailedWithError:(NSError *)error;
    // Handle connection failure

- (void)fileTransferProgressUpdate:(float)percent;
    // Get updates on the file being transferred

- (NSURLCredential *)credentialForAuthenticationChallenge;
	// Provides a credential to use when the connection sends an authentication challenge

/* deprecated */
- (void)connectionDownloadPercentUpdate:(float)percent;

@end