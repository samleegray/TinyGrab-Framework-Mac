//
//  TinyGrabDelegate.h
//  CloudieApp
//
//  Created by Sam Gray on 3/12/11.
//  Copyright 2011 Sam Gray. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol TinyGrabDelegate

-(void)uploadProgress:(int)percent;

@end
