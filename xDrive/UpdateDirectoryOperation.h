//
//  UpdateDirectoryOperation.h
//  xDrive
//
//  Created by Chris Gibbs on 3/6/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XService.h"

@interface UpdateDirectoryOperation : NSOperation

///---------------------
/// @name Initialization
///---------------------

/**
 Initializes the operation for the specified directory path.
 
 @param details The directory detials fetched from the server.
 @param directoryPath The directory path to update.
 */
- (id)initWithDetails:(NSDictionary *)details forDirectoryPath:(NSString *)directoryPath;

@end


