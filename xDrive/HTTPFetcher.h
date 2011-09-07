//
//  HTTPFetcher.h
//  ACU
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//
//  A derivative work based on code by Matt Gallagher, found at:
//  http://cocoawithlove.com/2011/05/classes-for-fetching-and-parsing-xml-or.html
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

@interface HTTPFetcher : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong, readonly) NSURLRequest *urlRequest;
@property (nonatomic, assign, readonly) int responseCode;
@property (nonatomic, strong, readonly) NSDictionary *responseHeaderFields;
@property (nonatomic, assign, readonly) NSInteger failureCode;
@property (nonatomic, assign) NSError *finalError;

@property (weak) id receiver;
@property SEL action;

@property (nonatomic, assign) BOOL displayAlerts;
@property (nonatomic, strong) NSURLCredential *tmpAuthCredential;
@property (nonatomic, strong) NSURLAuthenticationChallenge *challenge;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) UIAlertView *loginAlert;

- (id)initWithURLRequest:(NSURLRequest *)aURLRequest
				receiver:(id)aReceiver
				  action:(SEL)receiverAction;
- (id)initWithURLString:(NSString *)aURLString
			   receiver:(id)aReceiver
				 action:(SEL)receiverAction;
- (id)initWithURLString:(NSString *)aURLString
				timeout:(NSTimeInterval)aTimeoutInterval
			cachePolicy:(NSURLCacheStoragePolicy)aCachePolicy
			   receiver:(id)aReceiver
				 action:(SEL)receiverAction;
- (void)start;
- (void)finished;
- (void)cancel;
- (void)close;

- (void)respondToAuthenticationChallenge:(NSURLAuthenticationChallenge *)authChallenge;

@end



//
// Logging Macro
//
//#define NET_DEBUG
#ifdef NET_DEBUG
#	define NetLog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#	define NetLog(...)
#endif
