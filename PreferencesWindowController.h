//
//  PreferencesWindowController.h
//  MilkMaid
//
//  Created by Gregamel on 3/10/10.
//  Copyright 2010 JGA. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreferencesWindowController : NSWindowController {
	IBOutlet NSButton *menuBarIconButton;
	IBOutlet NSButton *dockIconButton;
}
-(IBAction)menuBarClicked:(id)sender;
-(IBAction)dockIconClicked:(id)sender;

@end
