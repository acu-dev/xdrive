//
//  UIStoryboard+Xdrive.m
//  xDrive
//
//  Created by Chris Gibbs on 2/3/12.
//  Copyright (c) 2012 Abilene Christian University. All rights reserved.
//

#import "UIStoryboard+Xdrive.h"

@implementation UIStoryboard (Xdrive)

+ (UIStoryboard *)mainStoryboard
{
    return [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
}

+ (UIStoryboard *)deviceStoryboard
{
	NSString *storyboardName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"MainStoryboard_iPhone" : @"MainStoryboard_iPad";
    return [UIStoryboard storyboardWithName:storyboardName bundle:nil];
}

@end
