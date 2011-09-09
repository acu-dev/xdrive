//
//  XService.h
//  xDrive
//
//  Created by Chris Gibbs on 7/1/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//


#import "XServiceLocal.h"
#import "XServiceRemote.h"
#import "XServer.h"
#import "AccountViewController.h"


@interface XService : NSObject

// Services
@property (nonatomic, strong) XServiceLocal *localService;
@property (nonatomic, strong) XServiceRemote *remoteService;

// One XService to rule them all
+ (XService *)sharedXService;

// Server
- (XServer *)activeServer;
- (void)saveServerWithDetails:(NSDictionary *)details;

// Server/account validation
//- (void)validateAccountDetails:(NSDictionary *)details withViewController:(AccountViewController *)viewController;

// Directory entries
- (XDirectory *)directoryWithPath:(NSString *)path;

@end



//
// Logging Macro
//
#define X_SVC_DEBUG
#ifdef X_SVC_DEBUG
#	define XSvcLog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#	define XSvcLog(...)
#endif