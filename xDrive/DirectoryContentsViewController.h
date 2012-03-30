//
//  DirectoryContentsViewController.h
//  xDrive
//
//  Created by Christopher Gibbs on 7/6/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "DirectoryViewController.h"
#import "XService.h"
@class XDirectory;

typedef enum {
	DirectoryContentNotChecked,
	DirectoryContentCached,
	DirectoryContentUpdating,
	DirectoryContentUpdateFinished,
	DirectoryContentUpdateFailed
} DirectoryContentStatus;

@interface DirectoryContentsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (strong, nonatomic) IBOutlet UILabel *actionLabel, *lastUpdatedLabel, *folderEmptyLabel;

@property (nonatomic, weak) DirectoryViewController *directoryViewController;

/**
 Directory object to display the contents of.
 */
@property (nonatomic, strong) XDirectory *directory;

@property (nonatomic, assign, readonly) DirectoryContentStatus contentStatus;

/**
 Updates the view to reflect the current status of the directory content.
 
 @param status The status of the directory content.
 */
- (void)updateDirectoryStatus:(DirectoryContentStatus)status;

- (void)setupDirectoryContentController;

@end
