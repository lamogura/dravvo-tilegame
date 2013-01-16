//
//  DVAPIWrapper.m
//  iostest
//
//  Created by Mogura on 12/6/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "DVDownloader.h"

@interface DVDownloader()

@end

@implementation DVDownloader

@synthesize receivedData;
@synthesize request;
@synthesize connection;

#pragma mark Initialization Methods
- (id) initWithRequest: (NSURLRequest*) req {
    self = [super init];
    if (self) {
        self.request = [req copy];
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        self.receivedData = [[NSMutableData alloc] init];
    }
    return self;
}

#pragma mark - NSURLConnection Delegate Methods
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [receivedData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDVDownloaderDidFinishDownloadingNotification object:self userInfo:[NSDictionary dictionaryWithObject:error forKey:kDVDownloaderErrorKey]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDVDownloaderDidFinishDownloadingNotification object:self];
}

@end
