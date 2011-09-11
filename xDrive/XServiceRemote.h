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

// Server
- (void)fetchServerVersion:(NSString *)host withTarget:(id)target action:(SEL)action;
	// Gets the server's version
- (void)fetchServerInfo:(NSString *)host withTarget:(id)target action:(SEL)action;
	// Gets the server's info

//- (void)fetchDefaultPath:(NSString *)path withTarget:(id)target action:(SEL)action;
//- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action;


@end
