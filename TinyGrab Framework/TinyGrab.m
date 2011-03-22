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

int uploadProgress(void *blah, double t, /* dltotal */ double d, /* dlnow */ double ultotal, double ulnow)
{
	int size = 100;
	double fractionDownloaded = ulnow / ultotal;
	int amountFull = round(fractionDownloaded * size);
	
	//printf("amountFull:%d\n", amountFull);
	
    [currentDelegate uploadProgress:amountFull];
    
	return 0;
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, char *s)
{	
	if (s == NULL) 
	{
		fprintf(stderr, "realloc() failed in writefunc(Cloudie.m)\n");
		exit(1);
	}
    
    NSMutableString *stringToParse = [[NSMutableString alloc] initWithUTF8String:(const char *)ptr];
    int deleteableAmount = [stringToParse length] - nmemb;
    [stringToParse deleteCharactersInRange:NSMakeRange([stringToParse length] - deleteableAmount, deleteableAmount)];
	
	[currentParser parseHeaderString:stringToParse];
	
	return size*nmemb;
}

@implementation TinyGrab

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
	currentParser = parser;
    currentDelegate = delegate;
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
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &stringBuffer);
		curl_easy_setopt(curl, CURLOPT_WRITEHEADER, &headerBuffer);
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, uploadProgress);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
	
	currentParser = nil;
	currentDelegate = nil;
    
	return(headerDictionary);
}

-(NSDictionary *)validateUser:(NSString *)emailString password:(NSString *)passwordString
{
	[parser startNewParseSet];
	currentParser = parser;
    currentDelegate = delegate;
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
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &stringBuffer);
		curl_easy_setopt(curl, CURLOPT_WRITEHEADER, &headerBuffer);
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
	
	currentParser = nil;
    currentDelegate = nil;
	
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


/*void TinyGrabStart(void)
{
	latestRequestStatus = CLOUDIE_FAIL;
	stringBuffer == NULL;
	
	curl_global_init(CURL_GLOBAL_ALL);
	curl = curl_easy_init();
	parser = [[HeaderParser alloc] init];
}

NSDictionary *TinyGrabValid(const char *email, const char *password)
{
	[parser startNewParseSet];
	CURLcode res2;
	
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
				 CURLFORM_COPYCONTENTS, makeMD5(password),
				 CURLFORM_END);
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, TINYGRAB_VERIFY_URL);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &stringBuffer);
		curl_easy_setopt(curl, CURLOPT_WRITEHEADER, &headerBuffer);
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
	
	return(headerDictionary);
}

NSDictionary *TinyGrabUploadImage(const char *fileName, const char *email, const char *password)
{
	[parser startNewParseSet];
	CURLcode res2;
	
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
				 CURLFORM_COPYCONTENTS, makeMD5(password),
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "upload",
				 CURLFORM_FILE, convertImage(fileName),
				 CURLFORM_END);
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, TINYGRAB_UPLOAD_URL);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &stringBuffer);
		curl_easy_setopt(curl, CURLOPT_WRITEHEADER, &headerBuffer);
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, uploadProgress);
		
		res2 = curl_easy_perform(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
	NSDictionary *headerDictionary = [NSDictionary dictionaryWithDictionary:[parser headerDictionary]];
	
	return(headerDictionary);
}

const char *convertImage(const char *file)
{
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:file]];
	NSData *data = [[NSBitmapImageRep imageRepWithData:
					 [image TIFFRepresentation]]
					representationUsingType:NSPNGFileType 
					properties:nil];
	NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSMutableString *uniqueFilename = [NSMutableString stringWithFormat:@"%@.jpg", uniqueString];
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFilename];
	[data writeToURL:[NSURL fileURLWithPath:filePath] atomically:NO];

	return([filePath UTF8String]);
}

const char *makeMD5(const char *stringToMD5)
{
	unsigned char md5pass[16];
	CC_MD5(stringToMD5, strlen(stringToMD5), md5pass);
	int i;
	NSMutableString *mutString = [NSMutableString string];
	for(i = 0; i <= 16; i++)
	{
		[mutString appendFormat:@"%02X", md5pass[i]];
	}

	[mutString deleteCharactersInRange:NSMakeRange([mutString length]-2, 2)];
	
	return([[mutString lowercaseString] UTF8String]);
}

void TinyGrabDestory(void)
{
	curl_easy_cleanup(curl);
	curl_global_cleanup();
	[parser release];
}*/