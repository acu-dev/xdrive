//
//  XServiceRemote.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceRemote.h"
#import "XDriveConfig.h"
#import "XService.h"
#import <CGNetUtils/CGNetUtils.h>



@interface XServiceRemote() <CGConnectionDelegate>

@property (nonatomic, strong) NSMutableDictionary *requests;
	// Container for each request's connection info

- (NSString *)serviceUrlString;
	// Returns an absolute url to the saved server's service base path.

- (NSString *)serviceUrlStringForHost:(NSString *)host;
	// Generates an absolute url to the service base path of the passed host
	// (uses the default vars defined in XDriveConfig.h. If host is nil the
	// details from the active server are used.
		
- (void)fetchJSONAtURL:(NSString *)url withTarget:(id)target action:(SEL)action;
	// Creates the connection and saves the target/action in the requests dictionary
	// to be used when the connection returns.

@end




static NSString *serviceInfoPath = @"/info";




@implementation XServiceRemote


@synthesize activeServer;
@synthesize requests;



- (id)initWithServer:(XServer *)server
{
    self = [super init];
    if (self)
	{
		activeServer = server;
		requests = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Utils

- (NSString *)serviceUrlString
{
	return [self serviceUrlStringForHost:nil];
}

- (NSString *)serviceUrlStringForHost:(NSString *)host
{
	int port = defaultServerPort;
	NSString *protocol = defaultServerProtocol;
	NSString *serviceBase = defaultServiceBasepath;
	
	if (activeServer)
	{
		protocol = activeServer.protocol;
		host = activeServer.hostname;
		port = [activeServer.port intValue];
		serviceBase = activeServer.servicePath;
	}
	
	if (!host)
		return nil;
	
	return [NSString stringWithFormat:@"%@://%@:%i%@",
			protocol,
			host,
			port,
			serviceBase];
}

- (NSString *)serverUrlString
{
	return [NSString stringWithFormat:@"%@://%@:%i",
			activeServer.protocol,
			activeServer.hostname,
			[activeServer.port intValue]];
}

- (void)fetchJSONAtURL:(NSString *)url withTarget:(id)target action:(SEL)action
{
	// Create connection
	CGConnection *connection = [[CGNet utils] getJSONAtURL:[NSURL URLWithString:url] withDelegate:self];
	
	// Save connection info
	NSDictionary *request = [[NSDictionary alloc] initWithObjectsAndKeys:
							 target, @"targetObject",
							 NSStringFromSelector(action), @"selectorString",
							 connection, @"connection",
							 nil];
	[requests setObject:request forKey:[connection description]];
	
	// Start request
	[connection start];
}



#pragma mark - Fetches

- (void)fetchServerInfoAtHost:(NSString *)host withTarget:(NSObject *)target action:(SEL)action
{
	NSString *infoServiceURLString = [[self serviceUrlStringForHost:host] stringByAppendingPathComponent:@"info"];
	[self fetchJSONAtURL:infoServiceURLString withTarget:target action:action];
}

- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action
{
	NSString *encodedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *directoryService = [[self serviceUrlString] stringByAppendingFormat:@"/directory/?path=%@", encodedPath];
	[self fetchJSONAtURL:directoryService withTarget:target action:action];
}



#pragma mark - Downloads

- (void)downloadFileAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	NSString *absolutePath = [[self serverUrlString] stringByAppendingString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	XDrvLog(@"absolute path: %@", absolutePath);
	
	// Create connection
	CGConnection *connection = [[CGNet utils] getFileAtURL:[NSURL URLWithString:absolutePath] withDelegate:self];
	
	// Save connection info
	NSDictionary *request = [[NSDictionary alloc] initWithObjectsAndKeys:
							 delegate, @"delegate",
							 connection, @"connection",
							 nil];
	[requests setObject:request forKey:[connection description]];
	
	// Start request
	[connection start];
}



#pragma mark - CGConnectionDelegate

- (void)cgConnection:(CGConnection *)connection finishedWithResult:(id)result
{
	// Get request details
	NSDictionary *request = [requests objectForKey:[connection description]];
	if (!request)
	{
		XDrvLog(@"- Error: Unable to find details for connection: %@; nothing to do", [connection description]);
		return;
	}
	
	if ([connection isKindOfClass:[CGJSONConnection class]])
	{
		// Send results off to request's target
		id target = [request objectForKey:@"targetObject"];
		SEL action = NSSelectorFromString([request objectForKey:@"selectorString"]);
		[target performSelector:action withObject:result];
	}
	else
	{
		// Send event off to delegate
		id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
		[delegate connectionFinishedWithResult:result];
	}
	
	// Clean up request
	request = nil;
	[requests removeObjectForKey:[connection description]];
}

- (void)cgConnection:(CGConnection *)connection failedWithError:(NSError *)error
{
	// Get request details
	NSDictionary *request = [requests objectForKey:[connection description]];
	if (!request)
	{
		XDrvLog(@"- Error: Unable to find details for connection: %@; nothing to do", [connection description]);
		return;
	}
	
	if ([connection isKindOfClass:[CGJSONConnection class]])
	{
		// Send results off to request's target
		id target = [request objectForKey:@"targetObject"];
		SEL action = NSSelectorFromString([request objectForKey:@"selectorString"]);
		[target performSelector:action withObject:error];
	}
	else
	{
		// Send event off to delegate
		id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
		[delegate connectionFailedWithError:error];
	}
	
	// Clean up request
	request = nil;
	[requests removeObjectForKey:[connection description]];
}

- (void)cgConnection:(CGConnection *)connection didReceiveData:(long long)receivedDataBytes 
  totalReceivedBytes:(long long)totalReceivedBytes expectedTotalBytes:(long long)expectedTotalBytes
{
	// Get request details
	NSDictionary *request = [requests objectForKey:[connection description]];
	if (!request)
	{
		XDrvLog(@"- Error: Unable to find details for connection: %@; nothing to do", [connection description]);
		return;
	}
	
	// Calculate percent of file downloaded
	int percent = lroundf(((float)totalReceivedBytes / (float)expectedTotalBytes) * 100);
	XDrvDebug(@"Download file percent done: %i%%", percent);
	
	id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
	if ([delegate respondsToSelector:@selector(connectionDownloadPercentUpdate:)])
	{
		// Send event off to delegate
		[delegate connectionDownloadPercentUpdate:percent];
	}
}


@end













