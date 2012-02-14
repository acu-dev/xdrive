//
//  OpenFileViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 9/18/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XFile.h"


@interface OpenFileViewController : UIViewController

@property (nonatomic, strong) XFile *xFile;
	// File object to display if needed and download

@property (nonatomic, strong) IBOutlet UIWebView *webView;
	// View to load file content in

@property (nonatomic, strong) IBOutlet UIView *downloadView;
	// View to show file download progress

@property (nonatomic, strong) IBOutlet UILabel *downloadFileNameLabel;
	// Label for file name

@property (nonatomic, strong) IBOutlet UIProgressView *downloadProgressView;
	// Progress bar to show percentage of file downloaded

+ (BOOL)isFileViewable:(XFile *)file;

@end
