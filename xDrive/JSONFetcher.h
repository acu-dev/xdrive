//
//  JSONFetcher.h
//  xDrive
//
//  Created by Chris Gibbs on 6/30/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//
//  A derivative work based on code by Matt Gallagher.
//  Found at: http://cocoawithlove.com/2011/05/classes-for-fetching-and-parsing-xml-or.html
//

#import "HTTPFetcher.h"

@interface JSONFetcher : HTTPFetcher
{
	id result;
}

@property (nonatomic, readonly) id result;

- (void)didReceiveInvalidJSONData:(NSString *)errorReason;

@end
