//
//  DirectoryViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 3/29/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XDirectory.h"
#import "XFile.h"

@interface DirectoryViewController : UIViewController

@property (nonatomic, strong) XDirectory *directory;
@property (nonatomic, strong) IBOutlet UIView *messageView;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (UIView *)initialUpdateMessageView;
- (UIView *)noContentsMessageView;

- (void)navigateToDirectory:(XDirectory *)directory;
- (void)navigateToFile:(XFile *)file;

@end
