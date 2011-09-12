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

@interface AccountViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField *serverURLField, *usernameField, *passwordField;
@property (nonatomic, strong) IBOutlet UILabel *signInLabel;
@property (nonatomic, strong) IBOutlet UITableViewCell *signInCell;

- (IBAction)textFieldValueChanged:(id)sender;
	// Checks if the form is now valid/invalid and enables/disables the sign in

- (void)updateValidateAccountStatus:(NSString *)status;
	// Called from XService during account validation. Updates the HUD with the status

- (void)validateAccountFailedWithError:(NSError *)error;
	// Called from XService after account validation has finished. Updates the HUD with the error message

- (void)validateAccountSucceeded;
	// Called from XService after account validation has finished. Updates the HUD with a success briefly, then dismisses this view

@end
