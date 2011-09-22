//
//  XDefaultPath.h
//  xDrive
//
//  Created by Chris Gibbs on 7/25/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

@class XDirectory, XServer;

@interface XDefaultPath : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * icon;
@property (nonatomic, retain) XServer *server;
@property (nonatomic, retain) XDirectory *directory;

@end
