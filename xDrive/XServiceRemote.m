//
//  XServiceRemote.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceRemote.h"
#import "XService.h"
#import <CGNetUtils/CGNetUtils.h>



@interface XServiceRemote() <CGConnectionDelegate>

@property (nonatomic, strong) NSMutableDictionary *requests;
	// Container for each request's connection info

- (NSString *)serviceUrlStringForHost:(NSString *)host;
		
- (void)startConnection:(CGConnection *)connection withTarget:(id)target action:(SEL)action;

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
	int port = 443;
	NSString *protocol = @"https";
	NSString *serviceBase = @"/xservice";
	
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



#pragma mark - Server

- (void)fetchServerVersion:(NSString *)host withTarget:(id)target action:(SEL)action
{
	NSString *versionServiceURLString = [[self serviceUrlStringForHost:host] stringByAppendingPathComponent:@"info"]; // change this to "version" when the service is available
	[self fetchJSONAtURL:versionServiceURLString withTarget:target action:action];
}

- (void)fetchServerInfo:(NSString *)host withTarget:(id)target action:(SEL)action
{
	NSString *infoServiceURLString = [[self serviceUrlStringForHost:host] stringByAppendingPathComponent:@"info"];
	[self fetchJSONAtURL:infoServiceURLString withTarget:target action:action];
}

#pragma mark - Fetches


/*- (void)fetchDefaultPath:(NSString *)path withTarget:(id)target action:(SEL)action
{
	NSString *directoryService = [[self serviceUrlString] stringByAppendingFormat:@"/directory/?path=%@", path];
	
	//XServiceFetcher *fetcher = [[XServiceFetcher alloc] initWithURLString:directoryService receiver:target action:action];
	//[fetcher start];
}*/

/*- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action
{
	NSString *encodedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *directoryService = [[self serviceUrlString] stringByAppendingFormat:@"/directory/?path=%@", encodedPath];
	
	//XServiceFetcher *fetcher = [[XServiceFetcher alloc] initWithURLString:directoryService receiver:self action:@selector(receiveResponse:)];
	
	// Save request data for handling upon return
	NSDictionary *request = [[NSDictionary alloc] initWithObjectsAndKeys:
							 target, @"targetObject",
							 NSStringFromSelector(action), @"selectorString",
							 fetcher, @"fetcher",
							 nil];
	[requests setObject:request forKey:[fetcher description]];
	
	// Fire off request
	[fetcher start];
}*/

#pragma mark - Responses

/*- (void)receiveResponse:(XServiceFetcher *)fetcher
{
	// Get request details
	NSDictionary *request = [requests objectForKey:[fetcher description]];
	if (!request)
	{
		NSLog(@"- Error: Unable to find request details for fetcher: %@; nothing to do", [fetcher description]);
		return;
	}
	
	if (!fetcher.result)
	{
		NSLog(@"- Error: No results found");
		return;
	}
	
	// Send results off to request's target
	id target = [request objectForKey:@"targetObject"];
	SEL action = NSSelectorFromString([request objectForKey:@"selectorString"]);
	[target performSelector:action withObject:fetcher.result];
	
	// Clean up request
	request = nil;
	[requests removeObjectForKey:[fetcher description]];
}*/



#pragma mark - CGConnectionDelegate

- (void)cgConnection:(CGConnection *)connection finishedWithResult:(id)result
{
	// Get request details
	NSDictionary *request = [requests objectForKey:[connection description]];
	if (!request)
	{
		NSLog(@"- Error: Unable to find details for connection: %@; nothing to do", [connection description]);
		return;
	}
	
	// Send results off to request's target
	id target = [request objectForKey:@"targetObject"];
	SEL action = NSSelectorFromString([request objectForKey:@"selectorString"]);
	[target performSelector:action withObject:result];
	
	// Clean up request
	request = nil;
	[requests removeObjectForKey:[connection description]];
}




@end
