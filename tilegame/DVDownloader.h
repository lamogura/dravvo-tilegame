//
//  DVAPIWrapper.h
//  iostest
//
//  Created by Mogura on 12/6/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DVDownloaderDidFinishDownloading @"DVDownloaderDidFinishDownloading"

@interface DVDownloader : NSObject <NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSMutableData *receivedData;
@property (strong, nonatomic) NSURLRequest *request;
@property (strong, nonatomic) NSURLConnection *connection;

- (id) initWithRequest: (NSURLRequest*) req;

@end
