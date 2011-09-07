//
//  XServer.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

@class XEntry;

@interface XServer : NSManagedObject

@property (nonatomic, retain) NSString * protocol;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, retain) NSString * servicePath;
@property (nonatomic, retain) NSSet *defaultPaths;
@property (nonatomic, retain) NSSet *entries;

@end

@interface XServer (CoreDataGeneratedAccessors)

- (void)addDefaultPathsObject:(NSManagedObject *)value;
- (void)removeDefaultPathsObject:(NSManagedObject *)value;
- (void)addDefaultPaths:(NSSet *)values;
- (void)removeDefaultPaths:(NSSet *)values;

- (void)addEntriesObject:(XEntry *)value;
- (void)removeEntriesObject:(XEntry *)value;
- (void)addEntries:(NSSet *)values;
- (void)removeEntries:(NSSet *)values;

@end
