//
//  PreferencesWindowController.m
//  MilkMaid
//
//  Created by Gregamel on 3/10/10.
//  Copyright 2010 JGA. All rights reserved.
//

#import "PreferencesWindowController.h"


@implementation PreferencesWindowController

-(void)awakeFromNib {
	changed = NO;
	[menuBarIconButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"menuicon"]];
	[dockIconButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"dockicon"]];
	[tagsInDropDownButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"tagsInDropDown"]];
	[self.window orderFrontRegardless];
}

-(void)menuBarClicked:(id)sender {
	if ([sender state] == NSOnState) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"menuicon"];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"menuicon"];
	}
	changed = YES;
}

-(void)dockIconClicked:(id)sender {
	if ([sender state] == NSOnState) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dockicon"];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"dockicon"];
	}
}

-(void)tagsInDropDownClicked:(id)sender {
	if ([sender state] == NSOnState) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"tagsInDropDown"];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"tagsInDropDown"];
	}
}

-(void)windowWillClose:(NSNotification *)notification {
	if (changed)
		[[[NSApplication sharedApplication] delegate] updateMenuIcon];
	[self release];
}

@end
