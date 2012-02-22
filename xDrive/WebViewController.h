//
//  WebViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 2/22/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;

- (void)loadContentAtURL:(NSURL *)url withTitle:(NSString *)title;

@end
