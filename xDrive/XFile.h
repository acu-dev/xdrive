//
//  XFile.h
//  xDrive
//
//  Created by Chris Gibbs on 2/15/12.
//  Copyright (c) 2012 Meld Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XEntry.h"


@interface XFile : XEntry

@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * sizeDescription;

- (NSString *)extension;
- (NSString *)cachePath;
- (NSString *)documentPath;

@end
