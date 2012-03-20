//
//  DirectoryContentsController.h
//  xDrive
//
//  Created by Chris Gibbs on 3/20/12.
//  Copyright (c) 2012 Meld Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XService.h"
#import "DirectoryContentsViewController.h"

@interface DirectoryContentsController : NSObject <XServiceRemoteDelegate>

- (id)initWithDirectory:(XDirectory *)directory forViewController:(DirectoryContentsViewController *)viewController;

- (void)updateDirectoryContents;

@end
