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

@property (nonatomic, strong) XDirectory *directory;
@property (nonatomic, weak) DirectoryViewController *directoryViewController;
@property (nonatomic, assign, readonly) DirectoryContentStatus contentStatus;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *arrowImageView;
@property (nonatomic, strong) IBOutlet UILabel *actionLabel, *lastUpdatedLabel, *folderEmptyLabel;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;

- (void)updateDirectoryStatus:(DirectoryContentStatus)status;
- (void)setupDirectoryContentController;

@end
