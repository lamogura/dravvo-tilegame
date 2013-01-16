//
//  DVAPIWrapper.m
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "SBJson.h"

#import "DVAPIWrapper.h"
#import "DVDownloader.h"
#import "DVConstants.h"
#import "DVGameStatus.h"
#import "DVMacros.h"

@interface DVAPIWrapper()  {
    NSMutableSet *connections; // downloader connections live
    NSMutableSet *observers; // notification observers live
}

@end

@implementation DVAPIWrapper

#pragma mark - API Functions
- (void) getAllMessagesAndCallBlock:(void (^)(NSError *,NSArray *))block {
    NSString *urlString = [NSString stringWithFormat:@"%@/message/all", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    DLog(@"Get to '%@'", urlString);
    
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:DVDownloaderDidFinishDownloading object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo) {
            NSError *err = [notification.userInfo objectForKey:@"error"];
            block(err, nil);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"Received JSON response: %@", jsonString);
            NSArray *messages = [DVGameStatus textMessageArrayFromJSON:jsonString];
            DLog(@"Contained %d messages.", [messages count]);
            block(nil, messages);
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

- (void) sendMessage:(DVGameStatus *)msg AndCallBlock:(void (^)(NSError *, DVGameStatus *msg))block {

}

- (void) deleteMessage:(DVGameStatus *)msg AndCallBlock:(void (^)(NSError *))block {

}

#pragma mark - Lifetime
- (id) init {
    self = [super init];
    if (self) {
        self->connections = [[NSMutableSet alloc] init];
        self->observers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) dealloc {
    // final chance to remove an observer
    for (id obj in self->observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:obj];
    }
    self->connections = nil;
    self->observers = nil;
}

@end
