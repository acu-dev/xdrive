//
//  XEntry.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

@class XDirectory, XServer;

@interface XEntry : NSManagedObject

@property (nonatomic, retain) NSDate *created;
@property (nonatomic, retain) NSString *creator;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSString *lastUpdator;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) XDirectory *parent;
@property (nonatomic, retain) XServer *server;

@end
