//
//  XDirectory.h
//  xDrive
//
//  Created by Chris Gibbs on 7/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XEntry.h"

@class XDefaultPath, XEntry;

@interface XDirectory : XEntry {
@private
}
@property (nonatomic, retain) NSSet *contents;
@property (nonatomic, retain) XDefaultPath *defaultPath;
@end

@interface XDirectory (CoreDataGeneratedAccessors)

- (void)addContentsObject:(XEntry *)value;
- (void)removeContentsObject:(XEntry *)value;
- (void)addContents:(NSSet *)values;
- (void)removeContents:(NSSet *)values;

@end
