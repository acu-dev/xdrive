//
//  AccountViewController.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//


@interface AccountViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, strong) IBOutlet UITextField *serverURLField, *usernameField, *passwordField;

- (IBAction)textFieldValueChanged:(id)sender;

- (IBAction)save:(id)sender;

@end
