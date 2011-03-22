/*
 *  Cloudie.h
 *  libcurl console tests
 *
 *  Created by Sam Gray on 11/29/10.
 *  Copyright 2010 Sam Gray. All rights reserved.
 *
 */

/* this file is PLAIN C;
 I have it in Objective-C file format so I can uses my Mac/iOS exclusive XMLParser class */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

#include "HeaderParser.h"
#import <CommonCrypto/CommonDigest.h>
#import "TinyGrabDelegate.h"

#define TINYGRAB_UPLOAD_URL "http://tinygrab.com/api/v3.php?m=grab/upload"
#define TINYGRAB_VERIFY_URL "http://tinygrab.com/api/v3.php?m=user/verify"

#define CLOUDIE_SUCCESS 0
#define CLOUDIE_FAIL 1

HeaderParser *currentParser;
id <TinyGrabDelegate> currentDelegate;

@interface TinyGrab : NSObject
{
@private
	CURL *curl;
	char *stringBuffer;
	char *headerBuffer;
	NSString *grabURL;
	int lastRequestStatus;
	HeaderParser *parser;
    id <TinyGrabDelegate> delegate;
}

-(id)initWithDelegate:(id <TinyGrabDelegate>)aDelegate;
-(NSDictionary *)uploadImage:(NSString *)filePathString email:(NSString *)emailString password:(NSString *)passwordString;
-(NSDictionary *)validateUser:(NSString *)emailString password:(NSString *)passwordString;

-(const char *)convertImage:(NSString *)filePathString;
-(const char *)makeMD5:(NSString *)stringToMD5;

@end



/*CURL *curl;
char *stringBuffer;
char *headerBuffer;
char *stringTest;
NSString *grabURL;
int latestRequestStatus;
//HeaderParser *parser;

void TinyGrabStart(void);
NSDictionary *TinyGrabUploadImage(const char *fileName, const char *email, const char *password);
NSDictionary *TinyGrabValid(const char *email, const char *password);
const char *convertImage(const char *filePath);
const char *makeMD5(const char *stringToMD5);
void TinyGrabDestory(void);*/

int uploadProgress(void *blah, double t, double d, double ultotal, double ulnow);
size_t writefunc(void *ptr, size_t size, size_t nmemb, char *s);
