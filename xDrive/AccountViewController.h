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

@property (nonatomic, strong) IBOutlet UIBarButtonItem *saveButton;

- (IBAction)textFieldValueChanged:(id)sender;
	// Checks if the form is now valid/invalid and enables/disables the sign in

- (IBAction)save:(id)sender;

@end
