/*
 *  Cloudie.cpp
 *  libcurl console tests
 *
 *  Created by Sam Gray on 11/29/10.
 *  Copyright 2010 Sam Gray. All rights reserved.
 *
 */

#include "TinyGrab.h"

#pragma mark -
#pragma mark libcurl callbacks

int uploadProgress(void *s, double t, /* dltotal */ double d, /* dlnow */ double ultotal, double ulnow)
{
    TinyGrab *tgSelf = (TinyGrab *)s;
    
	int size = 100;
	double fractionDownloaded = ulnow / ultotal;
	int amountFull = round(fractionDownloaded * size);
	
    if(amountFull != [tgSelf lastPercent])
    {
        [[tgSelf delegate] uploadProgress:amountFull];
        [tgSelf setLastPercent:amountFull];
    }
    
	return 0;
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, void *s)
{	
    TinyGrab *tgSelf = (TinyGrab *)s;
    
    NSMutableString *stringToParse = [[NSMutableString alloc] initWithUTF8String:(const char *)ptr];
    int deleteableAmount = [stringToParse length] - nmemb;
    [stringToParse deleteCharactersInRange:NSMakeRange([stringToParse length] - deleteableAmount, deleteableAmount)];
	
	[[tgSelf parser] parseHeaderString:stringToParse];
	
    [stringToParse release];
	return size*nmemb;
}

@implementation TinyGrab

@synthesize delegate;
@synthesize parser;
@synthesize lastPercent;

-(id)init
{
	self = [super init];
	if (self != nil) 
	{
		stringBuffer = NULL;
		
		curl_global_init(CURL_GLOBAL_ALL);
		curl = curl_easy_init();
		parser = [[HeaderParser alloc] init];
		
		return(self);
	}
	
	return(nil);
}

-(id)initWithDelegate:(id <TinyGrabDelegate>)aDelegate
{
    self = [super init];
    if (self != nil) 
    {
        stringBuffer = NULL;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        parser = [[HeaderParser alloc] init];
        delegate = aDelegate;
        
        return(self);
    }
    
    return(nil);
}

-(NSDictionary *)uploadImage:(NSString *)filePathString email:(NSString *)emailString password:(NSString *)passwordString
{
	[parser startNewParseSet];
	CURLcode res2;
	
	const char *email = [emailString UTF8String];
	const char *password = [self makeMD5:passwordString];
	const char *filePath = [self convertImage:filePathString];
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	static const char buf2[] = "Content-Type: multipart/form-data";
	
	curl_formadd(&formpost2, 
				 &lastptr2,
				 CURLFORM_COPYNAME, "User-Agent",
				 CURLFORM_COPYCONTENTS, "TinyGrab Mac 1.0 API/2",
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "email",
				 CURLFORM_COPYCONTENTS, email,
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "passwordhash",
				 CURLFORM_COPYCONTENTS, password,
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "upload",
				 CURLFORM_FILE, filePath,
				 CURLFORM_END);
	
	printf("%s %s %s\n", email, password, filePath);
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, TINYGRAB_UPLOAD_URL);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
        curl_easy_setopt(curl, CURLOPT_HEADER, 1L);
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, uploadProgress);
        curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, (void *)self);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
    
	return(headerDictionary);
}

-(NSDictionary *)validateUser:(NSString *)emailString password:(NSString *)passwordString
{
	[parser startNewParseSet];
	CURLcode res2;
	
	const char *email = [emailString UTF8String];
	const char *password = [self makeMD5:passwordString];
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	//static const char buf2[] = "Content-Type: multipart/form-data";
	static const char *buf2 = "Content-Type: multipart/form-data";
	
	curl_formadd(&formpost2, 
				 &lastptr2,
				 CURLFORM_COPYNAME, "User-Agent",
				 CURLFORM_COPYCONTENTS, "TinyGrab Mac 1.0 API/2",
				 CURLFORM_END);
	
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "email",
				 CURLFORM_COPYCONTENTS, email,
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "passwordhash",
				 CURLFORM_COPYCONTENTS, password,
				 CURLFORM_END);
	
	printf("%s %s\n", email, password);
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, TINYGRAB_VERIFY_URL);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		curl_easy_setopt(curl, CURLOPT_HEADER, 1L);
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
	
	return(headerDictionary);
}

-(const char *)convertImage:(NSString *)filePathString
{
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePathString];
	NSData *data = [[NSBitmapImageRep imageRepWithData:
					 [image TIFFRepresentation]]
					representationUsingType:NSPNGFileType 
					properties:nil];
	NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSMutableString *uniqueFilename = [NSMutableString stringWithFormat:@"%@.jpg", uniqueString];
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFilename];
	[data writeToURL:[NSURL fileURLWithPath:filePath] atomically:NO];
    
    [image release];
	
	return([filePath UTF8String]);
}

-(const char *)makeMD5:(NSString *)stringToMD5
{
	const char *CstringToMD5 = [stringToMD5 UTF8String];
	unsigned char md5pass[16];
	CC_MD5(CstringToMD5, strlen(CstringToMD5), md5pass);
	int i;
	NSMutableString *mutString = [NSMutableString string];
	for(i = 0; i <= 16; i++)
	{
		[mutString appendFormat:@"%02X", md5pass[i]];
	}
	
	[mutString deleteCharactersInRange:NSMakeRange([mutString length]-2, 2)];
	
	return([[mutString lowercaseString] UTF8String]);
}

-(void)dealloc
{
	curl_easy_cleanup(curl);
	curl_global_cleanup();
	[parser release];
	printf("release grabURL?\n");
	[grabURL release];
	printf("released it\n");
	[super dealloc];
}

@end