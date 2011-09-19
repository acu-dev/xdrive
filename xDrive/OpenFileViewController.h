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
	// The file object to download if needed and display

@property (nonatomic, strong) IBOutlet UIWebView *webView;

+ (BOOL)isFileViewable:(XFile *)file;

//- (id)initWithFile:(XFile *)file;

- (IBAction)done:(id)sender;

@end
