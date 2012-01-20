//
//  XServiceRemote.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServer.h"
#import <CGNetUtils/CGNetUtils.h>
@protocol XServiceRemoteDelegate;



@interface XServiceRemote : NSObject

@property (strong, nonatomic) XServer *activeServer;
	// Server info to use when building request URLs

- (id)initWithServer:(XServer *)server;
	// Saves the server to use for requests and initializes the requests storage

- (void)fetchServerInfoAtHost:(NSString *)host withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Gets the server info (version, service paths, etc)

- (void)fetchDefaultPathsWithDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Gets the server's configured default paths.

- (void)fetchDirectoryContentsAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Gets the directory contents for a path

/* Deprecated */

- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action;

- (void)downloadFileAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate;
- (void)downloadFileAtAbsolutePath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Downloads a file at given url path and notifies delegate on events


@end



@protocol XServiceRemoteDelegate <NSObject>

- (void)connectionFinishedWithResult:(NSObject *)result;
- (void)connectionFailedWithError:(NSError *)error;
	// Connection status

@optional

- (void)connectionDownloadPercentUpdate:(float)percent;
	// Provides an updated percentage of the file downloaded so the view can update (e.g. progress bar)

- (NSURLCredential *)credentialForAuthenticationChallenge;
	// Returns a credential to use when the connection sends an authentication challenge

@end