//
//  RTMHelper.m
//  SimpleRTM
//
//  Created by Greg Allen on 1/28/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "RTMHelper.h"

static int compare (id obj1, id obj2, void *context) {
	return [[obj1 objectForKey:@"priority"] compare:[obj2 objectForKey:@"priority"]];
}

@implementation RTMHelper


-(NSMutableArray*)getFlatTaskList:(NSDictionary *)rtmResponse {
	
	NSMutableArray *tasks = [[NSMutableArray alloc] init];
	
	NSDictionary *taskList = [rtmResponse objectForKey:@"tasks"];
	
	if (![taskList objectForKey:@"list"])
		return tasks;
	
	NSArray *listTasks = [self getArray:[[rtmResponse objectForKey:@"tasks"] objectForKey:@"list"]];

	for (NSDictionary *list in listTasks) {
		NSArray *taskSeriesList = [self getArray:[list objectForKey:@"taskseries"]];
		NSArray* taskSeriesListReversed = [[taskSeriesList reverseObjectEnumerator] allObjects];
		for (NSDictionary *taskSeries in taskSeriesListReversed) {
			NSDictionary *t = [taskSeries objectForKey:@"task"];
			NSDictionary *task = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[list objectForKey:@"id"], [taskSeries objectForKey:@"id"], 
																	  [t objectForKey:@"id"], [taskSeries objectForKey:@"name"], [t objectForKey:@"priority"] ,nil] 
															 forKeys:[NSArray arrayWithObjects:@"list_id", @"taskseries_id", @"task_id", @"name", @"priority", nil]];
			[tasks addObject:task];
		}
	}
	
	
	return [self sortTasks:tasks];
}

-(NSMutableArray*)sortTasks:(NSMutableArray*)tasks {
	[tasks sortUsingFunction:compare context:nil];
	return tasks;
}


-(NSArray*)getArray:(id)obj {
	if ([obj isKindOfClass:[NSArray class]]) {
		return obj;
	} else {
		return [NSArray arrayWithObject:obj];
	}
}

@end
