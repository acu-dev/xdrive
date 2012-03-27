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

@property (nonatomic, strong) XServer *_server;
@property (nonatomic, assign) BOOL _isRunning;
@property (nonatomic, copy) XServiceCompletionBlock _completionBlock;
@property (nonatomic, copy) XServiceUpdateBlock _updateBlock;

- (void)fetchJSONAtURL:(NSURL *)url;
- (void)downloadFileAtURL:(NSURL *)url ifModifiedSinceCachedDate:(NSDate *)cachedDate;

- (NSString *)serverURLString;
- (NSString *)serviceURLString;

@end






@implementation XServiceRemote

// Private
@synthesize _server;
@synthesize _isRunning;
@synthesize _completionBlock;
@synthesize _updateBlock;

// Public
@synthesize failureBlock;
@synthesize authenticationChallengeBlock;



- (id)initWithServer:(XServer *)server
{
	self = [super init];
    if (!self) return nil;
	_server = server;
	return self;
}



#pragma mark - Actions

- (BOOL)isRunning
{
	return _isRunning;
}

- (BOOL)start
{
	if ([self isRunning])
	{
		XDrvLog(@"Error: Unable to start - remote service is currently running");
		return NO;
	}
	_isRunning = YES;
	return YES;
}

- (void)finished
{
	_completionBlock = nil;
	_updateBlock = nil;
	
	_isRunning = NO;
}



#pragma mark - Getting Entry Details

- (void)fetchJSONAtURL:(NSURL *)url
{
	// Create connection
	CGJSONConnection *connection = [[CGNet utils] getJSONAtURL:url withDelegate:self];
	
	// Start request
	[connection start];
}

- (void)fetchDefaultPathsWithCompletionBlock:(XServiceCompletionBlock)completionBlock
{
	if (![self start]) return;
	_completionBlock = completionBlock;
	
	NSURL *defaultPathsURL = [NSURL URLWithString:[[self serviceURLString] stringByAppendingString:@"/paths"]];
	[self fetchJSONAtURL:defaultPathsURL];
}

- (void)fetchEntryDetailsAtPath:(NSString *)path withCompletionBlock:(XServiceCompletionBlock)completionBlock
{
	if (![self start]) return;
	_completionBlock = completionBlock;
	
	// Encode entry URL
	NSString *encodedPath = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																								  (__bridge CFStringRef)path,
																								  NULL,
																								  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																								  kCFStringEncodingUTF8);
	NSURL *entryURL = [NSURL URLWithString:[[self serviceURLString] stringByAppendingFormat:@"/entry/%@", encodedPath]];
	
	// Fetch
	[self fetchJSONAtURL:entryURL];
}



#pragma mark - Downloading Files

- (void)downloadFileAtURL:(NSURL *)url ifModifiedSinceCachedDate:(NSDate *)cachedDate
{
	// Create connection
	CGFileConnection *connection = [[CGNet utils] getFileAtURL:url withDelegate:self];
	if (cachedDate)
	{
		XDrvLog(@"Setting if modified since date: %@", cachedDate);
		[connection setIfModifiedSinceDate:cachedDate];
	}
	
	// Start request
	[connection start];
}

- (void)downloadFileAtPath:(NSString *)path ifModifiedSinceCachedDate:(NSDate *)cachedDate
		   withUpdateBlock:(XServiceUpdateBlock)updateBlock
		   completionBlock:(XServiceCompletionBlock)completionBlock
{
	if (![self start]) return;
	_updateBlock = updateBlock;
	_completionBlock = completionBlock;
	
	NSURL *absoluteURL = [NSURL URLWithString:[[self serverURLString] stringByAppendingString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	[self downloadFileAtURL:absoluteURL ifModifiedSinceCachedDate:cachedDate];
}



#pragma mark - Utils

- (NSString *)serverURLString
{
	return [NSString stringWithFormat:@"%@://%@:%i", _server.protocol, _server.hostname, [_server.port intValue]];
}

- (NSString *)serviceURLString
{
	return [[self serverURLString] stringByAppendingFormat:@"%@%@", _server.context, _server.servicePath];
}



#pragma mark - CGConnectionDelegate

- (void)cgConnection:(CGConnection *)connection finishedWithResult:(id)result
{
	XDrvDebug(@"Connection finished");
	_completionBlock(result);
	[self finished];
}

- (void)cgConnection:(CGConnection *)connection failedWithError:(NSError *)error
{
	XDrvDebug(@"Connection failed");
	if (failureBlock)
	{
		failureBlock(error);
	}
	[self finished];
}

- (void)cgConnection:(CGConnection *)connection didReceiveData:(long long)receivedDataBytes 
  totalReceivedBytes:(long long)totalReceivedBytes expectedTotalBytes:(long long)expectedTotalBytes
{
	float percent = (float)totalReceivedBytes / (float)expectedTotalBytes;
	XDrvDebug(@"Download file percent done: %f", percent);
	_updateBlock(percent);
}



#pragma mark - CGChallengeResponseDelegate

- (void)respondToAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
							  forHandler:(CGAuthenticationChallengeHandler *)challengeHandler
{
	XDrvDebug(@"Received auth challenge");
	if (authenticationChallengeBlock)
	{
		XDrvDebug(@"Resolving challenge with credential from authentication challenge block");
		[challengeHandler resolveWithCredential:authenticationChallengeBlock(challenge)];
	}
	else
	{
		XDrvLog(@"No authentication challenge block set");
	}
}


@end













