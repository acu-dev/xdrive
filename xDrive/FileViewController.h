//
//  FileViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 4/3/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XFile.h"

@interface FileViewController : UIViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIView *downloadView, *noFileSelectedView;
@property (nonatomic, strong) IBOutlet UILabel *downloadFileNameLabel;
@property (nonatomic, strong) IBOutlet UIProgressView *downloadProgressView;

+ (BOOL)isFileViewable:(XFile *)file;
- (void)loadFile:(XFile *)file;
- (void)hidePopover;

@end
