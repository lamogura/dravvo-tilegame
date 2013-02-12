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
#import "DVServerGameData.h"

static DVAPIWrapper* _wrapper;

@interface DVAPIWrapper()
{
    NSMutableSet *connections; // open downloader connections
    NSMutableSet *observers; // open notification observers
}
@end

@implementation DVAPIWrapper

+ (DVAPIWrapper *) staticWrapper
{
    if (_wrapper == nil) {
        _wrapper = [[DVAPIWrapper alloc] init];
    }
    return _wrapper;
}

#pragma mark - API Functions
- (void) getGameStatusForID:(NSString *)gameID callbackBlock:(void (^)(NSError* error, DVServerGameData* status))block;
{
    DLog(@"Fetching status for GameID: %@", gameID);
    
    NSString *urlString = [NSString stringWithFormat:@"%@/game/%@", kDVAPIServerURL, gameID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];

    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    DLog(@"GET '%@'", urlString);
    
    [self->connections addObject:downloader];
    
    // start observing notifications for the downloader
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kDVDownloaderDidFinishDownloadingNotification
                                                                    object:downloader
                                                                     queue:nil
                                                                usingBlock:^(NSNotification *notification)
    {
        // error from downloader
        if (notification.userInfo != nil)
        {
            NSError *error = [notification.userInfo objectForKey:kDVDownloaderErrorKey];
            block(error, nil);
        }
        else // can assume we have our desired response
        {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"SERVER response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            // error from server
            NSDictionary* errorDict = [resp valueForKey:kDVAPIJSONResponseKey_ErrorDict];
            if (errorDict != nil)
            {
                NSString *errorMessage = [errorDict objectForKey:kDVAPIJSONResponseErrorKey_Message];
                NSError *error = [NSError errorWithDomain:kDVAPIWrapperErrorDomain
                                                     code:0
                                                 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorMessage, @"")}];
                block(error, nil);
            }
            else
            {
                NSDictionary* gameDataDict = [resp objectForKey:kDVAPIJSONResponseKey_Game];
                NSAssert(gameDataDict != nil, @"Failed to get game from json response");
                
                DVServerGameData *status = [[DVServerGameData alloc] initWithDictionary:gameDataDict];
                block(nil, status);
            }
        }
        // this downloader has served its purpose so remove it
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer]; // observer for network connection notifications
    [downloader.connection start]; // start download manually

}

- (void) createNewGameForDeviceToken:(NSString *)deviceToken callbackBlock:(void (^)(NSError* error, DVServerGameData* status))block
{
    DLog(@"Using device token for post to server: %@", deviceToken);
    
    NSString *urlString = [NSString stringWithFormat:@"%@/game/new", kDVAPIServerURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *dataString = [NSString stringWithFormat:@"deviceToken=%@", deviceToken];
    NSString *dataLength = [NSString stringWithFormat:@"%d", [dataString length]];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [req setHTTPMethod:@"POST"];
    [req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:data];
    
    DLog(@"POST '%@' data: '%@'", urlString, dataString);
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    [self->connections addObject:downloader];
    
    // start observing downloader notifications
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kDVDownloaderDidFinishDownloadingNotification
                                                                    object:downloader
                                                                     queue:nil
                                                                usingBlock:^(NSNotification *notification)
    {
        // downloader error
        if (notification.userInfo != nil)
        {
            NSError *error = [notification.userInfo objectForKey:kDVDownloaderErrorKey];
            block(error, nil);
        }
        else
        {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"SERVER response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            // error from server
            NSDictionary* errorDict = [resp valueForKey:kDVAPIJSONResponseKey_ErrorDict];
            if (errorDict != nil)
            {
                NSString *errorMessage = [errorDict objectForKey:kDVAPIJSONResponseErrorKey_Message];
                NSError *error = [NSError errorWithDomain:kDVAPIWrapperErrorDomain
                                                     code:0
                                                 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorMessage, @"")}];
                block(error, nil);
            }
            else
            {
                NSDictionary* gameDataDict = [resp objectForKey:kDVAPIJSONResponseKey_Game];
                NSAssert(gameDataDict != nil, @"Failed to get game from json response");
                
                DVServerGameData *status = [[DVServerGameData alloc] initWithDictionary:gameDataDict];
                block(nil, status);
            }
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

- (void) postGameUpdates:(NSArray *)updates gameOverStatus:(GameOverStatus)gameOverStatus forGameID:(NSString *)gameID deviceToken:(NSString *)deviceToken callbackBlock:(void (^)(NSError* error))block
{
    NSAssert(gameID != nil, @"gameID was nil");
    NSAssert(updates != nil, @"updates was nil");
    
    DLog(@"Updating game status for GameID: %@", gameID);
    
#if LONELY_DEBUG
    NSString *urlString = [NSString stringWithFormat:@"%@/game/%@/mockupdate", kDVAPIServerURL, gameID];
#else
    NSString *urlString = [NSString stringWithFormat:@"%@/game/%@/update", kDVAPIServerURL, gameID];
#endif
    
    DLog(@"Using device token for post: %@", deviceToken);
   
    SBJsonWriter* jwriter = [[SBJsonWriter alloc] init];
    
    NSString* updatesAsJSON = [jwriter stringWithObject:updates];
    NSString *dataString = [NSString stringWithFormat:@"lastUpdate=%@&deviceToken=%@&gameOverStatus=%d",
                            updatesAsJSON, deviceToken, gameOverStatus];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *dataLength = [NSString stringWithFormat:@"%d", [dataString length]];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [req setHTTPMethod:@"POST"];
    [req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:data];
    
    DLog(@"POST '%@' data: '%@'", urlString, dataString);
    DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
    [self->connections addObject:downloader];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kDVDownloaderDidFinishDownloadingNotification object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        
        if (notification.userInfo != nil)
        {
            NSError *error = [notification.userInfo objectForKey:kDVDownloaderErrorKey];
            block(error);
        }
        else
        {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"SERVER response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            NSDictionary* errorDict = [resp valueForKey:kDVAPIJSONResponseKey_ErrorDict];
            if (errorDict != nil)
            {
                NSString *errorMessage = [errorDict objectForKey:kDVAPIJSONResponseErrorKey_Message];
                NSError *error = [NSError errorWithDomain:kDVAPIWrapperErrorDomain
                                                     code:0
                                                 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorMessage, @"")}];
                block(error);
            }
            else block(nil); // all ok no error to callback
        }
        
        [self->connections removeObject:downloader]; // downloader work is done
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

#pragma mark - Lifetime
- (id) init {
    if (self= [super init])
    {
        self->connections = [[NSMutableSet alloc] init];
        self->observers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) dealloc
{
    // final chance to remove an observer
    for (id obj in self->observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:obj];
    }
    
    // TODO: figure out if I should be removing open connections some other way besides setting to nil
    self->connections = nil;
    self->observers = nil;
}

@end