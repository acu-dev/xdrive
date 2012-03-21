//
//  DirectoryContentsViewController.h
//  xDrive
//
//  Created by Christopher Gibbs on 7/6/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XService.h"
@class XDirectory;

typedef enum {
	DirectoryContentNotChecked,
	DirectoryContentFetching,
	DirectoryContentFetchFailed,
	DirectoryContentCached,
	DirectoryContentUpdating,
	DirectoryContentUpdateFinished,
	DirectoryContentUpdateFailed
} DirectoryContentStatus;

@interface DirectoryContentsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

/**
 Directory object to display the contents of.
 */
@property (nonatomic, strong) XDirectory *directory;

/**
 Mapping of file mime-types to icon file names.
 */
@property (nonatomic, strong) NSDictionary *iconTypes;

/**
 Current status of the directory contents.
 */
@property (nonatomic, assign) DirectoryContentStatus contentStatus;

/**
 Updates the view to reflect the current status of the directory content.
 
 @param status The status of the directory content.
 */
- (void)updateDirectoryStatus:(DirectoryContentStatus)status;

@end
