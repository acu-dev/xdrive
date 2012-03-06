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
#import <CGNetUtils/CGNet.h>



@interface XServiceRemote() <CGConnectionDelegate, CGChallengeResponseDelegate>

@property (nonatomic, strong) NSMutableDictionary *requests;
	// Container for each request's connection info

- (NSString *)serverURLStringForHost:(NSString *)host;
- (NSString *)serverURLString;
	// Generates an absolute URL to the host using default protocol and port.
	// If no host is passed and an activeServer is present, activeServer is used.

- (NSString *)serviceURLStringForServer:(XServer *)server;
- (NSString *)serviceURLString;
	// Generates an absolute URL to the service base path of the passed host
	// (uses the default vars defined in XDriveConfig.h. If host is nil the
	// details from the active server are used.

@end






@implementation XServiceRemote


@synthesize activeServer;
@synthesize authDelegate;
@synthesize requests;



- (id)initWithServer:(XServer *)server
{
    self = [super init];
    if (self)
	{
		activeServer = server;
		requests = [[NSMutableDictionary alloc] init];
		[CGNet utils].challengeResponseDelegate = self;
    }
    return self;
}

#pragma mark - Utils

- (NSString *)serverURLStringForHost:(NSString *)host
{
	NSString *protocol = defaultServerProtocol;
	int port = defaultServerPort;
	
	if (!host && activeServer)
	{
		protocol = activeServer.protocol;
		port = [activeServer.port intValue];
		host = activeServer.hostname;
	}
	
	if (!host)
		return nil;
	
	NSString *serverURL = [NSString stringWithFormat:@"%@://%@:%i",
			protocol,
			host,
			port];
	//XDrvDebug(@"serverURL: %@", serverURL);
	
	return serverURL;
}

- (NSString *)serverURLString
{
	return [self serverURLStringForHost:nil];
}

- (NSString *)serviceURLStringForServer:(XServer *)server
{	
	if (!server) server = activeServer;
	return [[[self serverURLStringForHost:server.hostname] stringByAppendingString:server.context] stringByAppendingString:server.servicePath];
}

- (NSString *)serviceURLString
{
	return [self serviceURLStringForServer:nil];
}

- (void)fetchJSONAtURL:(NSString *)url withTarget:(id)target action:(SEL)action
{
	// Create connection
	CGJSONConnection *connection = [[CGNet utils] getJSONAtURL:[NSURL URLWithString:url] withDelegate:self];
	
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

- (void)fetchJSONAtURL:(NSString *)url withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	// Create connection
	CGJSONConnection *connection = [[CGNet utils] getJSONAtURL:[NSURL URLWithString:url] withDelegate:self];
	
	// Save connection info
	NSDictionary *request = [[NSDictionary alloc] initWithObjectsAndKeys:
							 delegate, @"delegate",
							 connection, @"connection",
							 nil];
	[requests setObject:request forKey:[connection description]];
	
	// Start request
	[connection start];
}



#pragma mark - Fetches

- (void)fetchInfoAtHost:(NSString *)host withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	NSString *infoServiceURLString = [[self serverURLStringForHost:host] stringByAppendingString:@"/xservice"];
	XDrvDebug(@"Getting info from URL: %@", infoServiceURLString);
	[self fetchJSONAtURL:infoServiceURLString withDelegate:delegate];
}

- (void)fetchDefaultPathsForServer:(XServer *)server withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	NSString *infoServiceURLString = [[self serviceURLStringForServer:server] stringByAppendingString:@"/paths"];
	XDrvDebug(@"Getting paths from URL: %@", infoServiceURLString);
	[self fetchJSONAtURL:infoServiceURLString withDelegate:delegate];
}

- (void)fetchDirectoryContentsAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	NSString *encodedPath = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
																						 NULL,
																						 (__bridge CFStringRef)path,
																						 NULL,
																						 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																						 kCFStringEncodingUTF8);
	NSString *directoryService = [[self serviceURLString] stringByAppendingFormat:@"/entry/%@", encodedPath];
	XDrvDebug(@"Getting directory contents at path: %@", directoryService);
	[self fetchJSONAtURL:directoryService withDelegate:delegate];
}

- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action
{
	NSString *encodedPath = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
																						 NULL,
																						 (__bridge CFStringRef)path,
																						 NULL,
																						 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																						 kCFStringEncodingUTF8);
	NSString *directoryService = [[self serviceURLString] stringByAppendingFormat:@"/entry/%@", encodedPath];
	XDrvDebug(@"Getting directory contents at path: %@", directoryService);
	[self fetchJSONAtURL:directoryService withTarget:target action:action];
}




#pragma mark - Downloads

- (void)downloadFileAtPath:(NSString *)path withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	NSString *absolutePath = [[self serverURLString] stringByAppendingString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[self downloadFileAtAbsolutePath:absolutePath ifModifiedSinceCachedDate:nil withDelegate:delegate];
}

- (void)downloadFileAtPath:(NSString *)path ifModifiedSinceCachedDate:(NSDate *)cachedDate withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	NSString *absolutePath = [[self serverURLString] stringByAppendingString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[self downloadFileAtAbsolutePath:absolutePath ifModifiedSinceCachedDate:cachedDate withDelegate:delegate];
}

- (void)downloadFileAtAbsolutePath:(NSString *)path ifModifiedSinceCachedDate:(NSDate *)cachedDate withDelegate:(id<XServiceRemoteDelegate>)delegate
{
	XDrvDebug(@"Downloading file at path: %@", path); 
	
	// Create connection
	CGFileConnection *connection = [[CGNet utils] getFileAtURL:[NSURL URLWithString:path] withDelegate:self];
	if (cachedDate)
	{
		XDrvLog(@"Setting if modified since date: %@", cachedDate);
		[connection setIfModifiedSinceDate:cachedDate];
	}
	
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
	XDrvDebug(@"Connection finished");
	//XDrvLog(@"result: %@", result);
	
	// Get request details
	NSDictionary *request = [requests objectForKey:[connection description]];
	if (!request)
	{
		XDrvLog(@"- Error: Unable to find details for connection: %@; nothing to do", [connection description]);
		return;
	}
	
	id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
	if (delegate)
	{
		// Send event off to delegate
		[delegate connectionFinishedWithResult:result];
	}
	else if ([request objectForKey:@"targetObject"])
	{
		// Send results off to request's target
		id target = [request objectForKey:@"targetObject"];
		SEL action = NSSelectorFromString([request objectForKey:@"selectorString"]);
		[target performSelector:action withObject:result];
	}
	else
	{
		// Call completion block
		
	}
	
	// Clean up request
	request = nil;
	[requests removeObjectForKey:[connection description]];
}

- (void)cgConnection:(CGConnection *)connection failedWithError:(NSError *)error
{
	XDrvDebug(@"Connection failed");
	
	// Get request details
	NSDictionary *request = [requests objectForKey:[connection description]];
	if (!request)
	{
		XDrvLog(@"- Error: Unable to find details for connection: %@; nothing to do", [connection description]);
		return;
	}
	
	id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
	if ([delegate respondsToSelector:@selector(connectionFailedWithError:)])
	{
		// Send event off to delegate
		[delegate connectionFailedWithError:error];
	}
	
	/*else
	{
		// Send results off to request's target
		id target = [request objectForKey:@"targetObject"];
		SEL action = NSSelectorFromString([request objectForKey:@"selectorString"]);
		[target performSelector:action withObject:error];
	}*/
	
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
	float percent = (float)totalReceivedBytes / (float)expectedTotalBytes;
	XDrvDebug(@"Download file percent done: %f", percent);
	
	id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
	if ([delegate respondsToSelector:@selector(connectionDownloadPercentUpdate:)])
	{
		// Send event off to delegate
		[delegate connectionDownloadPercentUpdate:percent];
	}
}



#pragma mark - CGChallengeResponseDelegate

- (void)respondToAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
							  forHandler:(CGAuthenticationChallengeHandler *)challengeHandler
{
	XDrvDebug(@"Received auth challenge");
	
	if (authDelegate)
	{
		// Get credential from auth delegate
		XDrvDebug(@"Asking auth delegate for credential");
		[challengeHandler resolveWithCredential:[authDelegate credentialForAuthenticationChallenge]];
		return;
	}
	
	
	// Get request details
	NSDictionary *request = [requests objectForKey:[challengeHandler.connection description]];
	if (!request)
	{
		XDrvLog(@"- Error: Unable to find details for connection: %@; nothing to do", [challengeHandler.connection description]);
		return;
	}
	id<XServiceRemoteDelegate> delegate = [request objectForKey:@"delegate"];
	
	if ([delegate respondsToSelector:@selector(credentialForAuthenticationChallenge)])
	{
		// Get credential to use from delegate
		[challengeHandler resolveWithCredential:[delegate credentialForAuthenticationChallenge]];
	}
	else
	{
		XDrvLog(@"No credential found; probably need to raise an authentication screen...");
	}
}


@end













