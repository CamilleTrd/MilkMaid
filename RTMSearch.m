//
//  RTMList.m
//  MilkMaid
//
//  Created by Gregamel on 3/11/10.
//  Copyright 2010 JGA. All rights reserved.
//

#import "RTMSearch.h"


@implementation RTMSearch

@synthesize title;
@synthesize listType;
@synthesize addParams;
@synthesize addAttributes;
@synthesize searchParams;

-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(id)initWithTitle:(NSString*)aTitle listType:(NSString*)aType searchParams:(NSDictionary*)aSearchParams addParams:(NSDictionary*)aAddParams {
	if (self=[super init]) {
		self.title = aTitle;
		self.listType = aType;
		self.searchParams = aSearchParams;
		self.addParams = aAddParams;
		self.addAttributes = nil;
	}
	return self;
}

-(id)initWithTitle:(NSString*)aTitle listType:(NSString*)aType searchParams:(NSDictionary*)aSearchParams addAttributes:(NSString*)aAddAttributes {
	if (self=[super init]) {
		self.title = aTitle;
		self.listType = aType;
		self.searchParams = aSearchParams;
		self.addParams = nil;
		self.addAttributes = aAddAttributes;
	}
	return self;
}

-(void)dealloc {
	[title release];
	[listType release];
	[searchParams release];
	[addParams release];
	[addAttributes release];
	[super dealloc];
}

@end
