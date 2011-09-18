//
//  XServiceRemote.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServer.h"
#import <CGNetUtils/CGNetUtils.h>

@interface XServiceRemote : NSObject

@property (strong, nonatomic) XServer *activeServer;
	// Server info to use when building request URLs

- (id)initWithServer:(XServer *)server;
	// Saves the server to use for requests and initializes the requests storage

- (void)fetchServerInfoAtHost:(NSString *)host withTarget:(NSObject *)target action:(SEL)action;
	// Gets the server's info. If host is nil the active server will be used.

- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action;
	// Gets the directory contents for a path

@end
