//
//  LocalStorageViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 2/16/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocalStorageViewController : UITableViewController

@property (nonatomic, strong) IBOutlet UILabel *usageLabel;
@property (nonatomic, strong) IBOutlet UIProgressView *usageProgressView;

@end
