//
//  SetupViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 10/7/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

@interface SetupViewController : UIViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *bgImageView;
@property (nonatomic, strong) IBOutlet UIView *centeringView;
@property (nonatomic, strong) IBOutlet UITextField *serverField, *usernameField, *passwordField;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)dismissKeyboard:(id)sender;
- (IBAction)login:(id)sender;

@end
