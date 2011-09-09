//
//  XServiceRemote.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceFetcher.h"
#import "XServer.h"

@interface XServiceRemote : NSObject

@property (strong, nonatomic) XServer *server;

- (id)initWithServer:(XServer *)aServer;

- (void)fetchServerInfo:(NSString *)host withTarget:(id)target action:(SEL)action;

- (void)fetchDefaultPath:(NSString *)path withTarget:(id)target action:(SEL)action;
- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action;

- (void)receiveResponse:(XServiceFetcher *)fetcher;

@end
