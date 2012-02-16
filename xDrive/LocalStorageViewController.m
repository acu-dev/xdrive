//
//  LocalStorageViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 2/16/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "LocalStorageViewController.h"

@interface LocalStorageViewController ()

@property (nonatomic, strong) NSIndexPath *selectedStorageIndexPath;

@end

@implementation LocalStorageViewController

// Public
@synthesize  usageLabel;
@synthesize usageProgressView;

// Private
@synthesize selectedStorageIndexPath;



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    
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



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
