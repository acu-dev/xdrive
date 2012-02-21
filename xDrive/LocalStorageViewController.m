//
//  LocalStorageViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 2/16/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "LocalStorageViewController.h"
#import "XDriveConfig.h"
#import "XService.h"



@interface LocalStorageViewController ()

@property (nonatomic, strong) NSIndexPath *selectedStorageIndexPath;

- (void)updateStorageUsage;
- (void)setLocalStorageOption:(NSDictionary *)option;
- (void)deleteCachedFiles;

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

	// Set currently selected storage option
	NSArray *storageOptions = [XDriveConfig localStorageOptions];
	NSInteger selectedIndex = [storageOptions indexOfObject:[XDriveConfig localStorageOption]];
	selectedStorageIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:1];
	
	// Set amount used
	[self updateStorageUsage];
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
		[self deleteCachedFiles];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}



#pragma mark - Local Storage

- (void)updateStorageUsage
{
	long long maxBytesAvailable = [[[XDriveConfig localStorageOption] objectForKey:@"bytes"] longLongValue];
	long long bytesCached = [XDriveConfig totalCachedBytes];
	float percentUsed = (float)bytesCached / (float)maxBytesAvailable;
	[usageProgressView setProgress:percentUsed animated:NO];
	
	usageLabel.text = [NSString stringWithFormat:@"Used %3.2f%% of %@", percentUsed, [[XDriveConfig localStorageOption] objectForKey:@"description"]];
	
	XDrvLog(@"maxBytesAvailable: %1.2f", (float)maxBytesAvailable);
	XDrvLog(@"bytesCached: %1.2f", (float)bytesCached);
	XDrvLog(@"percentUsed: %1.2f", percentUsed);
}

- (void)setLocalStorageOption:(NSDictionary *)option
{
	[XDriveConfig setLocalStorageOption:option];
	
	if ([[option objectForKey:@"bytes"] longLongValue] == 0)
	{
		[self deleteCachedFiles];
	}
	else
	{
		[[XService sharedXService] removeOldCacheUntilTotalCacheIsLessThanBytes:[[option objectForKey:@"bytes"] longLongValue]];
		[self updateStorageUsage];
	}
}

- (void)deleteCachedFiles
{
	[[XService sharedXService] clearCache];
	[self updateStorageUsage];
}

@end
















