//
//  DirectoryContentsViewController.h
//  xDrive
//
//  Created by Christopher Gibbs on 7/6/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"
@class XDirectory;

@interface DirectoryContentsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

/**
 Directory object to display the contents of.
 */
@property (nonatomic, strong) XDirectory *directory;

/**
 Mapping of file mime-types to icon file names.
 */
@property (nonatomic, strong) NSDictionary *iconTypes;

@end
