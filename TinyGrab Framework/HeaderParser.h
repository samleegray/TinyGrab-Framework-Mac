//
//  HeaderParser.h
//  CloudieApp
//
//  Created by Sam Gray on 2/18/11.
//  Copyright 2011 Sam Gray. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HeaderParser : NSObject 
{
	NSMutableDictionary *headerDictionary;
}

@property(readonly)NSMutableDictionary *headerDictionary;

-(void)startNewParseSet;
-(void)parseHeaderString:(NSString *)parseString;
-(NSString *)parseTitleString:(NSString *)headerString;
-(NSString *)parseDataString:(NSString *)headerString;

@end
