//
//  XDefaultPath.h
//  xDrive
//
//  Created by Chris Gibbs on 7/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XDirectory, XServer;

@interface XDefaultPath : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) XServer *server;
@property (nonatomic, retain) XDirectory *directory;

@end
