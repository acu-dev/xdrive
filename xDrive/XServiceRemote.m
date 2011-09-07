//
//  XServiceRemote.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceRemote.h"
#import "XService.h"

//
// Private interface
//
@interface XServiceRemote()
@property (nonatomic, strong) NSMutableDictionary *requests;
- (NSString *)serviceUrlString;
@end




static NSString *serviceInfoPath = @"/info";

@implementation XServiceRemote

@synthesize server;
@synthesize requests;

- (id)initWithServer:(XServer *)aServer
{
    self = [super init];
    if (self)
	{
		server = aServer;
		requests = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Accessors

- (NSString *)serviceUrlString
{
	if (!server)
		return nil;
	
	NSString *urlString = [NSString stringWithFormat:@"%@://%@:%i%@",
						   server.protocol,
						   server.hostname,
						   [server.port intValue],
						   server.servicePath];
	return urlString;
}

#pragma mark - Account Info

- (void)fetchServerInfo:(NSDictionary *)accountDetails withTarget:(id)target action:(SEL)action
{
	// Default lookup values until we get the official ones from the info service.
	//		Someday this could make a couple attempts with different values until
	//		it found the info service.
	int defaultPort = 443;
	NSString *defaultProtocol = @"https";
	NSString *defaultServiceBase = @"/xservice";
	
	// Build info service url
	NSString *infoServiceUrlString = [NSString stringWithFormat:@"%@://%@:%i%@%@",
									  defaultProtocol,
									  [accountDetails objectForKey:@"serverHost"],
									  defaultPort,
									  defaultServiceBase,
									  serviceInfoPath];
	
	XServiceFetcher *fetcher = [[XServiceFetcher alloc] initWithURLString:infoServiceUrlString receiver:target action:action];
	
	// Create temporary auth credentials
	NSURLCredential *tmpCredential = [NSURLCredential credentialWithUser:[accountDetails objectForKey:@"username"]
																password:[accountDetails objectForKey:@"password"]
															 persistence:NSURLCredentialPersistenceNone];
	fetcher.tmpAuthCredential = tmpCredential;
	
	[fetcher start];
}

#pragma mark - Fetches

- (void)fetchDefaultPath:(NSString *)path withTarget:(id)target action:(SEL)action
{
	NSString *directoryService = [[self serviceUrlString] stringByAppendingFormat:@"/directory/?path=%@", path];
	
	XServiceFetcher *fetcher = [[XServiceFetcher alloc] initWithURLString:directoryService receiver:target action:action];
	[fetcher start];
}

- (void)fetchDirectoryContentsAtPath:(NSString *)path withTarget:(id)target action:(SEL)action
{
	NSString *encodedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *directoryService = [[self serviceUrlString] stringByAppendingFormat:@"/directory/?path=%@", encodedPath];
	
	XServiceFetcher *fetcher = [[XServiceFetcher alloc] initWithURLString:directoryService receiver:self action:@selector(receiveResponse:)];
	
	// Save request data for handling upon return
	NSDictionary *request = [[NSDictionary alloc] initWithObjectsAndKeys:
							 target, @"targetObject",
							 NSStringFromSelector(action), @"selectorString",
							 fetcher, @"fetcher",
							 nil];
	[requests setObject:request forKey:[fetcher description]];
	
	// Fire off request
	[fetcher start];
}

#pragma mark - Responses

- (void)receiveResponse:(XServiceFetcher *)fetcher
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
}

@end
