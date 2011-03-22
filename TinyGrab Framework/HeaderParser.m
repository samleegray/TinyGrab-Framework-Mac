//
//  HeaderParser.m
//  CloudieApp
//
//  Created by Sam Gray on 2/18/11.
//  Copyright 2011 Sam Gray. All rights reserved.
//

#import "HeaderParser.h"


@implementation HeaderParser

@synthesize headerDictionary;

-(void)startNewParseSet
{
	headerDictionary = nil;
	headerDictionary = [[NSMutableDictionary alloc] init];
}

-(void)parseHeaderString:(NSString *)parseString
{	
	NSString *titleString = [self parseTitleString:parseString];
	NSString *dataString = [self parseDataString:parseString];
	
	if(titleString != nil && dataString != nil)
	{
		[headerDictionary setValue:[self parseDataString:parseString] forKey:[self parseTitleString:parseString]];
	}
}

-(NSString *)parseTitleString:(NSString *)headerString
{
	NSRange parseRange = [headerString rangeOfString:@": "];
	if (parseRange.length != 0) 
	{
		NSString *titleString = [headerString substringWithRange:NSMakeRange(0, parseRange.location)];
		return(titleString);
	}
	
	return(nil);
}

-(NSString *)parseDataString:(NSString *)headerString
{
	NSRange parseRange = [headerString rangeOfString:@": "];
	if (parseRange.length != 0) 
	{
		NSUInteger dataStartLocation = (parseRange.location + parseRange.length);
		NSUInteger dataEndLocation = ([headerString rangeOfString:@"\n"].location - 1);
		NSString *dataString = [headerString substringWithRange:NSMakeRange(dataStartLocation, dataEndLocation - dataStartLocation)];
		return(dataString);
	}
	
	return(nil);
}

-(void)dealloc
{
	[headerDictionary release];
	[super dealloc];
}

@end
