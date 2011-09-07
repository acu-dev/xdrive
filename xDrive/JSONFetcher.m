//
//  JSONFetcher.m
//  xDrive
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//
//  A derivative work based on code by Matt Gallagher.
//  Found at: http://cocoawithlove.com/2011/05/classes-for-fetching-and-parsing-xml-or.html
//

#import "JSONFetcher.h"

@implementation JSONFetcher

@synthesize result;

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
	[super close];
	
	result = nil;
}

- (void)didReceiveInvalidJSONData:(NSString *)errorReason
{
	NSString *title = NSLocalizedStringFromTable(@"Invalid Data", @"HTTPFetcher", @"Title for dialog rejecting invalid JSON data returned from server");
	NSString *button = NSLocalizedStringFromTable(@"OK", @"HTTPFetcher", @"Standard dialog dismiss button.");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:errorReason delegate:nil cancelButtonTitle:button otherButtonTitles:nil];
	[alert show];
}

#pragma mark - NSURLConnectionDataDelegate Overrides

//
// connectionDidFinishLoading:
//
// When the connection is complete, parse the JSON and reconstruct
//
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// Check for errors
	if (self.failureCode)
	{
		NSString *msg = NSLocalizedStringFromTable(@"Request failed with code %i", @"HTTPFetcher", @"Message displayed when the request fails");
		[self didReceiveInvalidJSONData:msg];
		[self close];
		return;
	}
	
	// Check for invalid data
	if ([[super data] length] == 0)
    {
		NSString *msg = NSLocalizedStringFromTable(@"No data returned", @"HTTPFetcher", @"Message displayed when no data was returned from server");
		[self didReceiveInvalidJSONData:msg];
		[self close];
		return;
	}

	// Convert data
	NSError *error = nil;
	result = [NSJSONSerialization JSONObjectWithData:[super data] options:0 error:&error];
	if (error)
	{
		[self didReceiveInvalidJSONData:[error localizedDescription]];
	}
	
	[self close];
}
 
@end
