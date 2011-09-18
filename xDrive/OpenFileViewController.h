//
//  OpenFileViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 9/18/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XFile.h"


@interface OpenFileViewController : UIViewController

@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet UIWebView *webView;

- (id)initWithFile:(XFile *)file;

- (IBAction)done:(id)sender;

@end
