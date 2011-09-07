//
//  DirectoryNavigationController.h
//  xDrive
//
//  Created by Christopher Gibbs on 7/7/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XDirectory.h"

@interface DirectoryNavigationController : UINavigationController

- (id)initWithRootPath:(NSString *)path;
- (id)initWithDirectory:(XDirectory *)directory;

@end
