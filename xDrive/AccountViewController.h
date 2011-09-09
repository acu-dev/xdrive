//
//  AccountViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "ATMHud.h"
#import "ATMHudDelegate.h"
#import <CGNetUtils/CGNetUtils.h>

@interface AccountViewController : UITableViewController <ATMHudDelegate, UITextFieldDelegate, CGConnectionDelegate, CGChallengeResponseDelegate>

@property (nonatomic, strong) IBOutlet UITextField *serverURLField, *usernameField, *passwordField;
@property (nonatomic, strong) IBOutlet UILabel *signInLabel;
@property (nonatomic, strong) IBOutlet UITableViewCell *signInCell;

- (IBAction)textFieldValueChanged:(id)sender;

- (void)validateAccount;

- (BOOL)isFormValid;
- (void)enableSignIn;
- (void)disableSignIn;

@end
