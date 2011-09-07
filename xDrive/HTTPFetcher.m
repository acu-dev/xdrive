//
//  HTTPFetcher.m
//  ACU
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//
//  A derivative work based on code by Matt Gallagher.
//  Found at: http://cocoawithlove.com/2011/05/classes-for-fetching-and-parsing-xml-or.html
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "HTTPFetcher.h"



@interface HTTPFetcher()


@property (nonatomic, strong) NSArray *trustedHosts;


//@property (nonatomic, strong, readwrite) NSMutableData *data;


@end




@implementation HTTPFetcher

// Private
@synthesize receiver;
@synthesize action;
@synthesize trustedHosts;
@synthesize connection;
@synthesize data;
@synthesize challenge;

// Public
@synthesize displayAlerts;
@synthesize tmpAuthCredential;
@synthesize urlRequest;
@synthesize responseHeaderFields;
@synthesize responseCode;
@synthesize failureCode;
@synthesize loginAlert;
@synthesize finalError;

#pragma mark - Initialization

//
// initWithURLString:receiver:action
//
// Init method for the object.
//
- (id)initWithURLRequest:(NSURLRequest *)aURLRequest
				receiver:(id)aReceiver
				  action:(SEL)receiverAction
{
	self = [super init];
	if (self != nil)
	{
		// remove this and set it in a subclass
		trustedHosts = [NSArray arrayWithObjects:@"deborah.acu.edu", nil];
		
		action = receiverAction;
		receiver = aReceiver;
		urlRequest = aURLRequest;
		connection = [[NSURLConnection alloc] initWithRequest:aURLRequest
													 delegate:self
											 startImmediately:NO];
	}
	return self;
}

//
// initWithURLString:receiver:action:
//
// Convenience constructor that constructs the NSURLRequest from a string
//
// Parameters:
//    aURLString - the string from the URL
//    aReceiver - the receiver
//    receiverAction - the selector on the receiver
//
// returns the initialized object
//
- (id)initWithURLString:(NSString *)aURLString
			   receiver:(id)aReceiver
				 action:(SEL)receiverAction
{
	//
	// Create the URL request and invoke super
	//
	NSURL *url = [NSURL URLWithString:aURLString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

	return [self initWithURLRequest:request receiver:aReceiver action:receiverAction];
}

//
// initWithURLString:timeout:cachePolicy:receiver:action:
//
// Convenience constructor that constructs the NSURLRequest and set the timeout
// and cache policy
//
// Parameters:
//    aURLString - the string from the URL
//    aTimeoutInterval - the timeout for the request
//    aCachePolicy - the cache policy (so no cache can be specified)
//    aReceiver - the receiver
//    receiverAction - the selector on the receiver
//
// returns the initialized object
//
- (id)initWithURLString:(NSString *)aURLString 
				timeout:(NSTimeInterval)aTimeoutInterval
			cachePolicy:(NSURLCacheStoragePolicy)aCachePolicy
			   receiver:(id)aReceiver
				 action:(SEL)receiverAction
{
	//
	// Create the URL request and invoke super
	//
	NSURL *url = [NSURL URLWithString:aURLString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setTimeoutInterval:aTimeoutInterval];
	[request setCachePolicy:aCachePolicy];

	return [self initWithURLRequest:request receiver:aReceiver action:receiverAction];
}

#pragma mark - Connection Actions

//
// start
//
// Start the connection
//
- (void)start
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[connection start];
}

//
// finished
//
// Messages the receiver that the connection is finished
//
- (void)finished
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[receiver performSelector:action withObject:self];
}

//
// close
//
// Cancel the connection and release all connection data. Does not release
// the result if already generated (this is only released when the class is
// released).
//
// Will send the response if the receiver is non-nil. But always releases the
// receiver when done.
//
- (void)close
{
	[connection cancel];
	connection = nil;
	
	challenge = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[receiver performSelector:action withObject:self];
	receiver = nil;

	data = nil;
}

//
// cancel
//
// Sets the receiver to nil (so it won't receive a response and then closes the
// connection and frees all data.
//
- (void)cancel
{
	receiver = nil;
	[self close];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{	
	if (buttonIndex != [alertView cancelButtonIndex])
	{
		
		// User tapped login button
		NSString *username = [alertView textFieldAtIndex:0].text;
		NSString *password = [alertView textFieldAtIndex:1].text;
		
		if (username == nil || password == nil) {
			[[challenge sender] cancelAuthenticationChallenge:challenge];
			return;
		}
		
		// Create a new credential from user login info
		NSURLCredential *newCredential = [NSURLCredential credentialWithUser:username 
																	password:password 
																 persistence:NSURLCredentialPersistenceForSession];
		
		// Save credential to storage
		[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:newCredential
															forProtectionSpace:[challenge protectionSpace]];
		
		// Respond to auth challenge with credential
		[[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
	}
	else
	{
		// User tapped cancel button
		//[[challenge sender] cancelAuthenticationChallenge:challenge];
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)aConnection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)aChallenge
{
	// Detailed server info
	/*NetLog(@"Received challenge for protection space:");
	NetLog(@"- host: %@", aChallenge.protectionSpace.host);
	NetLog(@"- port: %i", aChallenge.protectionSpace.port);
	NetLog(@"- protocol: %@", aChallenge.protectionSpace.protocol);
	NetLog(@"- realm: %@", aChallenge.protectionSpace.realm);
	NetLog(@"- authMethod: %@", aChallenge.protectionSpace.authenticationMethod);*/
	
	// Authenticate the server's certificate (if trusted)
	if ([aChallenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] && trustedHosts)
	{
		if ([trustedHosts containsObject:aChallenge.protectionSpace.host])
		{
			NetLog(@"Trusting host %@", aChallenge.protectionSpace.host);
			[aChallenge.sender useCredential:[NSURLCredential credentialForTrust:aChallenge.protectionSpace.serverTrust] forAuthenticationChallenge:aChallenge];
			return;
		}
		else
		{
			NetLog(@"Host %@ does not have a valid certificate, add it to trustedHosts if you want to trust it", aChallenge.protectionSpace.host);
			[aChallenge.sender rejectProtectionSpaceAndContinueWithChallenge:aChallenge];
			return;
		}
	}
	
	if (![aChallenge previousFailureCount])
	{
		// Only support HTTP basic auth
		if ([aChallenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic])
		{
			NetLog(@"Auth method is HTTP Basic");
			
			if (tmpAuthCredential)
			{
				NetLog(@"Found temporary auth credential; responding to challenge with it");
				[[aChallenge sender] useCredential:tmpAuthCredential forAuthenticationChallenge:aChallenge];
				tmpAuthCredential = nil;
			}
			else
			{
				[self respondToAuthenticationChallenge:aChallenge];
			}
		}
		else
		{
			NetLog(@"Unsupported authentication method");
		}
	}
	else
	{
		NetLog(@"Too many authentication failures");
		// Create error
		NSError *error = [NSError errorWithDomain:aChallenge.protectionSpace.host code:NSURLErrorUserCancelledAuthentication userInfo:nil];
		[self connection:aConnection didFailWithError:error];
		//[self finished];
	}
}

//
// connection:didFailWithError:
//
// Remove the connection and display an error message.
//
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	NetLog(@"Connection failed with code: %i", [error code]);
	
	NSError *newError = nil;
	
	// Replace some standard error messages with stomething a little more descriptive
	switch ([error code]) {
			
		case -1009:
		{
			// NSURLErrorNotConnectedToInternet
			NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:[error userInfo]];
			[newDictionary setObject:NSLocalizedStringFromTable(@"Unable to connect to server.",
																@"HTTPFetcher",
																@"Description for error when unable to connect to server.")
							  forKey:NSLocalizedDescriptionKey];
			newError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:newDictionary];
			break;
		}
			
		case -1012:
		{
			// NSURLErrorUserCancelledAuthentication
			NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:[error userInfo]];
			[newDictionary setObject:NSLocalizedStringFromTable(@"Username or password incorrect.",
																@"HTTPFetcher",
																@"Description for error rejecting username or password on login.")
							  forKey:NSLocalizedDescriptionKey];
			newError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:newDictionary];
			break;
		}
			
		default:
			newError = error;
			break;
	}
	
	finalError = newError;
	[self finished];
}

#pragma mark - NSURLConnectionDataDelegate

//
// connection:didReceiveResponse:
//
// When a start-of-message is received from the server, set the data to zero.
//
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSHTTPURLResponse *)aResponse
{	
	responseHeaderFields = [aResponse allHeaderFields];
	responseCode = [aResponse statusCode];
	
	NetLog(@"Received response with status: %i", responseCode);

	// Handle HTTP errors (Status codes of 400 and up)
	if (responseCode >= 400)
	{
		// Create generic NSError referencing the HTTP status code
		NSString *desc = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Server returned a status code of %i", 
																			   @"HTTPFetcher",
																			   @"Error given when the server responds with a status code >400. Placeholder is replaced with the HTTP status code."),
						  responseCode];
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:desc, NSLocalizedDescriptionKey, nil];
		finalError = [NSError errorWithDomain:@"HTTPFetcher" code:responseCode userInfo:errorInfo];
		
		[self close];
		return;
	}
	
	//
	// Handle the content-length if present by preallocating.
	//
	NSInteger contentLength = [[responseHeaderFields objectForKey:@"Content-Length"] integerValue];
	if (contentLength > 0)
	{
		data = [[NSMutableData alloc] initWithCapacity:contentLength];
	}
	else
	{
		data = [[NSMutableData alloc] init];
	}
}

//
// connection:didReceiveData:
//
// Append the data chunck to the download.
//
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)newData
{
	NetLog(@"Got data");
	[data appendData:newData];
}

//
// connectionDidFinishLoading:
//
// Override this in specific fetch implementations (JSON, XML, etc).
// When the connection is complete, parse the received data
//
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	NetLog(@"All done");
}

#pragma mark - Customization

//
// respondToAuthenticationChallenge:
//
// Override this in application specific implementation to present user
// with custom login/settings view.
//
- (void)respondToAuthenticationChallenge:(NSURLAuthenticationChallenge *)authChallenge
{
	NetLog(@"Prompting user to authenticate via login alert");
	
	challenge = authChallenge;
	
	NSString *title = NSLocalizedStringFromTable(@"Server requires login", @"HTTPFetcher", @"Title used for login dialog window.");
	NSString *cancelTitle = NSLocalizedStringFromTable(@"Cancel", @"HTTPFetcher", @"Standard dialog cancel button.");
	NSString *otherTitle = NSLocalizedStringFromTable(@"Login", @"HTTPFetcher", @"Button to submit login details and connect to the server");
	
	loginAlert = [[UIAlertView alloc] initWithTitle:title message:@"blee" delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
	loginAlert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
	[loginAlert show];
}

@end
