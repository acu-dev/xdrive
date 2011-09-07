//
//  DirectoryContentsViewController.h
//  xDrive
//
//  Created by Christopher Gibbs on 7/6/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

@class XDirectory;

@interface DirectoryContentsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) XDirectory *directory;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (id)initWithDirectory:(XDirectory *)dir;

@end
