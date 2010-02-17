//
//  SimpleRTMAppDelegate.m
//  SimpleRTM
//
//  Created by Gregamel on 1/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MilkMaidAppDelegate.h"
#define TOKEN @"Token"
#define LAST_LIST @"LastList"
@implementation MilkMaidAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	NSString *apiKey = @"1734ba9431007c2242b6865a69940aa5";
	NSString *secret = @"72d1c12ffb26e759";
	
	priority1Image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"priority1" ofType:@"png"]];
	priority2Image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"priority2" ofType:@"png"]];
	priority3Image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"priority3" ofType:@"png"]];
	
	[progress setForeColor:[NSColor whiteColor]];
	[progress startAnimation:nil];
	
//	[addTaskPanel orderOut:self];
	
	[taskTable setDelegate:self];
	[taskTable setDataSource:self];
	
	rtmController = [[EVRZRtmApi alloc] initWithApiKey:apiKey andApiSecret:secret];
	[NSThread detachNewThreadSelector:@selector(checkToken) toTarget:self withObject:nil];
}

- (void)checkToken {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString * token = [[NSUserDefaults standardUserDefaults] objectForKey:TOKEN];
	
	if (token) {
		rtmController.token = token;
		NSDictionary *data = [rtmController dataByCallingMethod:@"rtm.auth.checkToken" andParameters:[[NSDictionary alloc]init] withToken:YES];
		if ([[data objectForKey:@"stat"] isEqualToString:@"ok"]) {
			timeline = [rtmController timeline];
			[timeline retain];
			[self performSelectorOnMainThread:@selector(getLists) withObject:nil waitUntilDone:NO];
		} else {
			[self getAuthToken];
		}
		
	} else {
		[self getAuthToken];
	}
	[pool release];
}

-(void)getAuthToken {
	NSString *frob = [rtmController frob];
	NSString *url = [rtmController authUrlForPerms:@"delete" withFrob:frob];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
	[self performSelectorOnMainThread:@selector(showAuthMessage:) withObject:frob waitUntilDone:NO];
	//[self showAuthMessage:frob];	
}

-(void)showAuthMessage:(NSString*)frob {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Done"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Accept Permissions"];
	[alert setInformativeText:@"A browser has been opened. Please press the \"OK, I'll allow it\" button then press the Done button below."];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		NSString *token = [rtmController tokenWithFrob:frob];
		rtmController.token = token;
		[[NSUserDefaults standardUserDefaults] setObject:token forKey:TOKEN];
		[self performSelectorOnMainThread:@selector(getLists) withObject:nil waitUntilDone:NO];
		//[self doneLoading];
		
		
	}
	[alert release];
}

- (void)getLists {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *data = [rtmController dataByCallingMethod:@"rtm.lists.getList" andParameters:[[NSDictionary alloc]init] withToken:YES];
	lists = [[data objectForKey:@"lists"] objectForKey:@"list"];
	NSMutableArray *listToRemove = [[NSMutableArray alloc]init];
	for (NSDictionary *list in lists) {
		if ([[list objectForKey:@"archived"] intValue] == 0) {
			[listPopUp addItemWithTitle:[list objectForKey:@"name"]];
		} else {
			[listToRemove addObject:list];
		}
	}
	for (NSDictionary *list in listToRemove) {
		[lists removeObject:list];
	}
	[listToRemove release];
	[lists retain];
	//[data release];
	[pool release];
	[progress setHidden:YES];
	[self performSelectorOnMainThread:@selector(selectLast) withObject:nil waitUntilDone:NO];
}
	 
-(void)selectLast {
	NSString *lastList = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_LIST];
	if (lastList) {
		[listPopUp selectItemWithTitle:lastList];
		[self listSelected:nil];
	}
}

-(void)listSelected:(id)sender {

	NSInteger selectedIndex = [listPopUp indexOfSelectedItem];
	selectedIndex--;
	if (selectedIndex != -1 && [currentList objectForKey:@"id"] != [[lists objectAtIndex:selectedIndex] objectForKey:@"id"]) {
		currentList = [lists objectAtIndex:selectedIndex];
		[[NSUserDefaults standardUserDefaults] setObject:[currentList objectForKey:@"name"] forKey:LAST_LIST];
		[NSThread detachNewThreadSelector:@selector(getTasks) toTarget:self withObject:nil];
		
		[currentList retain];
	}
}
-(void)getTasks {
	if (currentList) {
		[self getTasksFromCurrentList];
	} else {
		[self searchTasks:currentSearch];
	}

}
-(void)getTasksFromCurrentList {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[currentList objectForKey:@"id"], @"status:incomplete", nil] 
														 forKeys:[NSArray arrayWithObjects:@"list_id", @"filter", nil]];
	NSDictionary *data = [rtmController dataByCallingMethod:@"rtm.tasks.getList" andParameters:params withToken:YES];
	
	RTMHelper *rtmHelper = [[RTMHelper alloc] init];
	
	tasks = [rtmHelper getFlatTaskList:data];

	[self performSelectorOnMainThread:@selector(loadTaskData) withObject:nil waitUntilDone:NO];
	
	[tasks retain];
	[rtmHelper release];
	[pool release];
	[progress setHidden:YES];
}

-(void)searchTasks:(NSString*)searchString {
	[progress setHidden:NO];
	NSString *newSearch = [NSString stringWithFormat:@"(%@) AND status:incomplete", searchString];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:newSearch, nil] 
														 forKeys:[NSArray arrayWithObjects:@"filter", nil]];
	NSDictionary *data = [rtmController dataByCallingMethod:@"rtm.tasks.getList" andParameters:params withToken:YES];
	
	RTMHelper *rtmHelper = [[RTMHelper alloc] init];
	
	tasks = [rtmHelper getFlatTaskList:data];
	
	[self performSelectorOnMainThread:@selector(loadTaskData) withObject:nil waitUntilDone:NO];
	
	[tasks retain];
	[pool release];
	[progress setHidden:YES];
}

-(void)refresh:(id)sender {
	[NSThread detachNewThreadSelector:@selector(getTasks) toTarget:self withObject:nil];
}

-(void)loadTaskData {
	//NSLog(@"%@", tasks);
	[window setTitle:[NSString stringWithFormat:@"MilkMaid (%d)", [tasks count]]];
	[[[NSApplication sharedApplication] dockTile] setBadgeLabel:[[NSNumber numberWithInt:[tasks count]] stringValue]];
	[taskTable reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [tasks count];
}

+ (NSColor *) colorFromHexRGB:(NSString *) inColorString
{
	NSColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result = [NSColor
			  colorWithCalibratedRed:		(float)redByte	/ 0xff
			  green:	(float)greenByte/ 0xff
			  blue:	(float)blueByte	/ 0xff
			  alpha:1.0];
	return result;
}
								
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	//check type of cell
	
	id cell = [tableColumn dataCellForRow:row];
	//NSLog(@"%@", cell);
	if ([cell isMemberOfClass:[BWTransparentCheckboxCell class]]) {
		return [NSNumber numberWithInteger:NSOffState];
	} else if ([cell isMemberOfClass:[NSImageCell class]]) {
		NSDictionary *task = [tasks objectAtIndex:row];
		NSString *pri = [task objectForKey:@"priority"];
		if ([pri isEqualToString:@"1"]) {
			return priority1Image;
		} else if ([pri isEqualToString:@"2"]) {
			return priority2Image;
		} else if ([pri isEqualToString:@"3"]) {
			return priority3Image;
		} else {
			return nil;
		}
	} else {//if ([cell isMemberOfClass:[BWTransparentTableViewCell class]]) {
		NSDictionary *task = [tasks objectAtIndex:row];
		

		[cell setTextColor:[NSColor whiteColor]];
		

		id due = [task objectForKey:@"due"];
		if ([due isKindOfClass:[NSDate class]] && ([due isPastDate] || [[NSDate date] isEqualToDate:due])) {
			[cell setBold:YES];
		} else {
			[cell setBold:NO];
		}

		return [task objectForKey:@"name"];
	}
	
}


				
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSDictionary *task = [tasks objectAtIndex:row];
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, [task objectForKey:@"list_id"], [task objectForKey:@"taskseries_id"], [task objectForKey:@"task_id"], nil] 
														 forKeys:[NSArray arrayWithObjects:@"timeline", @"list_id", @"taskseries_id", @"task_id", nil]];

	[tasks removeObject:task];
	[NSThread detachNewThreadSelector:@selector(completeTask:) toTarget:self withObject:params];
	[self loadTaskData];
}

-(void)completeTask:(NSDictionary *)taskInfo {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *data = [rtmController dataByCallingMethod:@"rtm.tasks.complete" andParameters:taskInfo withToken:YES];
	[pool release];
	[progress setHidden:YES];
}

-(void)showAddTask:(id)sender {

	if (!addTaskWindowController)
		addTaskWindowController = [[AddTaskWindowController alloc] initWithWindowNibName:@"AddTask"];
	NSWindow *sheet = [addTaskWindowController window];
	[NSApp beginSheet:sheet modalForWindow:window modalDelegate:self 
	   didEndSelector:@selector(closeAddTaskSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)closeAddTaskSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	if (returnCode == 1) {
		NSString *task = [addTaskWindowController task];
		[NSThread detachNewThreadSelector:@selector(addTask:) toTarget:self withObject:task];
	}

}

-(void)addTask:(NSString*)task {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, task, @"1", nil] 
														 forKeys:[NSArray arrayWithObjects:@"timeline", @"name", @"parse", nil]];
	if (currentList) {
		[params setObject:[currentList objectForKey:@"id"] forKey:@"list_id"];
	}
	[rtmController dataByCallingMethod:@"rtm.tasks.add" andParameters:params withToken:YES];
	
	[self getTasks];
	[pool release];
	[progress setHidden:YES];
}

-(void)addTasks:(NSArray*)newTasks {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	for (NSString *t in newTasks) {
		
		NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, t, @"1", nil] 
																		   forKeys:[NSArray arrayWithObjects:@"timeline", @"name", @"parse", nil]];
		if (currentList) {
			[params setObject:[currentList objectForKey:@"id"] forKey:@"list_id"];
		}
		[rtmController dataByCallingMethod:@"rtm.tasks.add" andParameters:params withToken:YES];
		
	}
	[self getTasks];
	[pool release];
	[progress setHidden:YES];

}

-(void)showLists:(id)sender {
	[listPopUp performClick:self];
}

-(void)menuPriority:(id)sender {
	NSInteger rowIndex = [taskTable selectedRow];
	if (rowIndex == -1)
		return;
	NSDictionary *task = [tasks objectAtIndex:rowIndex];
	
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, [task objectForKey:@"list_id"], [task objectForKey:@"taskseries_id"], [task objectForKey:@"task_id"], [sender title], nil] 
														 forKeys:[NSArray arrayWithObjects:@"timeline", @"list_id", @"taskseries_id", @"task_id", @"priority", nil]];
	[NSThread detachNewThreadSelector:@selector(setPriority:) toTarget:self withObject:params];
}
						
-(void)setPriority:(NSDictionary*)params {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[rtmController dataByCallingMethod:@"rtm.tasks.setPriority" andParameters:params withToken:YES];
	
	[self getTasks];
	[pool release];
	[progress setHidden:YES];
}

-(void)menuDueDate:(id)sender {
	NSInteger rowIndex = [taskTable selectedRow];
	if (rowIndex == -1)
		return;
	NSDictionary *task = [tasks objectAtIndex:rowIndex];
	
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, [task objectForKey:@"list_id"], [task objectForKey:@"taskseries_id"], [task objectForKey:@"task_id"], [sender title], @"1", nil] 
														 forKeys:[NSArray arrayWithObjects:@"timeline", @"list_id", @"taskseries_id", @"task_id", @"due", @"parse", nil]];
	[NSThread detachNewThreadSelector:@selector(setDueDate:) toTarget:self withObject:params];
}

-(void)setDueDate:(NSDictionary*)params {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[rtmController dataByCallingMethod:@"rtm.tasks.setDueDate" andParameters:params withToken:YES];
	
	[self getTasks];
	[pool release];
	[progress setHidden:YES];
}

-(void)menuPostponeTask:(id)sender {
	NSInteger rowIndex = [taskTable selectedRow];
	if (rowIndex == -1)
		return;
	NSDictionary *task = [tasks objectAtIndex:rowIndex];
	
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, [task objectForKey:@"list_id"], [task objectForKey:@"taskseries_id"], [task objectForKey:@"task_id"], nil] 
														 forKeys:[NSArray arrayWithObjects:@"timeline", @"list_id", @"taskseries_id", @"task_id", nil]];
	[NSThread detachNewThreadSelector:@selector(postponeTask:) toTarget:self withObject:params];
}

-(void)postponeTask:(NSDictionary*)params {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[rtmController dataByCallingMethod:@"rtm.tasks.postpone" andParameters:params withToken:YES];
	
	[self getTasks];
	[pool release];
	[progress setHidden:YES];
}

-(void)menuDeleteTask:(id)sender {
	NSInteger rowIndex = [taskTable selectedRow];
	if (rowIndex == -1)
		return;
	NSDictionary *task = [tasks objectAtIndex:rowIndex];
	
	NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:timeline, [task objectForKey:@"list_id"], [task objectForKey:@"taskseries_id"], [task objectForKey:@"task_id"], nil] 
														 forKeys:[NSArray arrayWithObjects:@"timeline", @"list_id", @"taskseries_id", @"task_id", nil]];
	[NSThread detachNewThreadSelector:@selector(deleteTask:) toTarget:self withObject:params];
}

-(void)deleteTask:(NSDictionary*)params {
	[progress setHidden:NO];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[rtmController dataByCallingMethod:@"rtm.tasks.delete" andParameters:params withToken:YES];
	
	[self getTasks];
	[pool release];
	[progress setHidden:YES];
}

-(void)menuSearch:(id)sender {
	if (!searchWindowController)
		searchWindowController = [[SearchWindowController alloc] initWithWindowNibName:@"Search"];
	NSWindow *sheet = [searchWindowController window];
	[NSApp beginSheet:sheet modalForWindow:window modalDelegate:self 
	   didEndSelector:@selector(closeSearchSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)closeSearchSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	if (returnCode == 1) {
		currentSearch = [searchWindowController searchString];
		currentList = nil;
		[currentSearch retain];
		[listPopUp selectItemAtIndex:0];
		[NSThread detachNewThreadSelector:@selector(searchTasks:) toTarget:self withObject:currentSearch];
	}
	
}

-(void)menuMultiAdd:(id)sender {
	if (!multiAddWindowController)
		multiAddWindowController = [[MultiAddWindowController alloc] initWithWindowNibName:@"MultiAdd"];
	NSWindow *sheet = [multiAddWindowController window];
	[NSApp beginSheet:sheet modalForWindow:window modalDelegate:self 
	   didEndSelector:@selector(closeMultiAddSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)closeMultiAddSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	if (returnCode == 1) {
		NSArray *newTasks = [multiAddWindowController tasks];
		[NSThread detachNewThreadSelector:@selector(addTasks:) toTarget:self withObject:newTasks];
	}
	
}

@end
