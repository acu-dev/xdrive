//
//  LocalStorageViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 2/16/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "LocalStorageViewController.h"
#import "XDriveConfig.h"



@interface LocalStorageViewController ()

@property (nonatomic, strong) NSIndexPath *selectedStorageIndexPath;

- (void)setLocalStorageOption:(NSDictionary *)option;

@end



@implementation LocalStorageViewController

// Public
@synthesize  usageLabel;
@synthesize usageProgressView;

// Private
@synthesize selectedStorageIndexPath;



#pragma mark - Initialization

- (void)awakeFromNib
{

}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Set selected storage option
	NSArray *storageOptions = [XDriveConfig localStorageOptions];
	NSInteger selectedIndex = [storageOptions indexOfObject:[XDriveConfig localStorageOption]];
	selectedStorageIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:1];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.usageLabel = nil;
	self.usageProgressView = nil;
	
	self.selectedStorageIndexPath = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView cellForRowAtIndexPath:selectedStorageIndexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
	{
		if (indexPath.row != selectedStorageIndexPath.row)
		{
			// Set local storage
			[self setLocalStorageOption:[[XDriveConfig localStorageOptions] objectAtIndex:indexPath.row]];
			
			// Unselect previous row
			[tableView cellForRowAtIndexPath:selectedStorageIndexPath].accessoryType = UITableViewCellAccessoryNone;
			
			// Select new row
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
			selectedStorageIndexPath = indexPath;
		}
	}
	else
	{
		// Clear cache
		XDrvLog(@"Need to clear cached files");
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}



#pragma mark - Local Storage

- (void)setLocalStorageOption:(NSDictionary *)option
{
	XDrvLog(@"selected option: %@", option);
}

@end
















