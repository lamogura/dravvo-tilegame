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
    NSMutableSet *connections; // open downloader connections
    NSMutableSet *observers; // open notification observers
}
@end

@implementation DVAPIWrapper

#pragma mark - API Functions
- (void) getGameStatusThenCallBlock:(void (^)(NSError* error, DVGameStatus* status))block {
    
    NSString* currentGameID = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentGameIDKey];
    
    // TODO: remove gameID from NSUserDefaults after gameOver update is sent
    // NOTE: what should happen when you try to get a game state for one that doesnt exist in NSUserDefaults ??
    // create a new game if there isnt a current one
    if (currentGameID == nil) {
        ULog(@"No currentGameID found.");
    }
    else {
        DLog(@"Fetching status for GameID: %@", currentGameID);
        
        NSString *urlString = [NSString stringWithFormat:@"%@/game/%@", kBaseURL, currentGameID];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
        
        DVDownloader *downloader = [[DVDownloader alloc] initWithRequest:req];
        DLog(@"GET '%@'", urlString);
        
        [self->connections addObject:downloader];
        
        // start observing notifications for the downloader
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kDVDownloaderDidFinishDownloadingNotification object:downloader queue:nil usingBlock:^(NSNotification *notification) {
            
            // error from downloader
            if (notification.userInfo) {
                NSError *error = [notification.userInfo objectForKey:kDVDownloaderErrorKey];
                block(error, nil);
            }
            else {
                NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
                DLog(@"SERVER response: %@", jsonString);
                NSDictionary *resp = [jsonString JSONValue];
                
                // error from server
                if ([resp valueForKey:kDVAPIErrorKey] != nil) {
                    NSString *errorMessage = [[resp objectForKey:kDVAPIErrorKey] objectForKey:kDVAPIErrorMsgKey];
                    NSError *error = [NSError errorWithDomain:kDVAPIWrapperErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorMessage, @"")}];
                    block(error, nil);
                } else {
                    DVGameStatus *status = [[DVGameStatus alloc] initWithDictionary:[resp objectForKey:kDVAPIGameKey]];
                    block(nil, status);
                }
            }
            // this downloader has served its purpose so remove it
            [self->connections removeObject:downloader];
        }];
        
        [self->observers addObject:observer]; // observer for network connection notifications
        [downloader.connection start]; // start download manually
    }
}

- (void) postCreateNewGameThenCallBlock:(void (^)(NSError* error, DVGameStatus* status))block {
    
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceToken];
    DLog(@"Loaded deviceToken from defaults: %@", deviceToken);
    
    NSString *urlString = [NSString stringWithFormat:@"%@/game/new", kBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // TODO: query the real device token and insert into post data string, now using "b"
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
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kDVDownloaderDidFinishDownloadingNotification object:downloader queue:nil usingBlock:^(NSNotification *notification) {
        
        // downloader error
        if (notification.userInfo) {
            NSError *error = [notification.userInfo objectForKey:kDVDownloaderErrorKey];
            block(error, nil);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
            DLog(@"SERVER response: %@", jsonString);
            NSDictionary *resp = [jsonString JSONValue];
            
            // server error
            if ([resp valueForKey:kDVAPIErrorKey] != nil) {
                NSString *errorMessage = [[resp objectForKey:kDVAPIErrorKey] objectForKey:kDVAPIErrorMsgKey];
                NSError *error = [NSError errorWithDomain:kDVAPIWrapperErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorMessage, @"")}];
                block(error, nil);
            } else {
                DVGameStatus *status = [[DVGameStatus alloc] initWithDictionary:[resp objectForKey:kDVAPIGameKey]];
                block(nil, status);
            }
        }
        
        [self->connections removeObject:downloader];
    }];
    
    [self->observers addObject:observer];
    [downloader.connection start]; // setup to have to start manually
}

- (void) postUpdateGameWithUpdates:(NSDictionary *)updates ThenCallBlock:(void (^)(NSError* error))block {
    
    NSString* gameID = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentGameIDKey];
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceToken];
    DLog(@"Loaded deviceToken from defaults: %@", deviceToken);
    
    
    if (gameID == nil) {
        ULog(@"No GameID found when trying to update...");
        // NOTE: need some other logic when trying to update game status before new game called ??
    }
    else {
        DLog(@"Updating status for GameID: %@", gameID);
        SBJsonWriter* jwriter = [[SBJsonWriter alloc] init];
        
        NSString* updatesAsJSON;
        NSString *dataString;
        
        // treat the isGameOver entry in updates dict specially, if exists remove it and send it in separate POST variable
        if ([updates objectForKey:kIsGameOver] == nil) {
            updatesAsJSON = [jwriter stringWithObject:updates];
            dataString = [NSString stringWithFormat:@"lastUpdate=%@&deviceToken=%@", updatesAsJSON, deviceToken];
            // TODO: faking deviceToken, replace with call to get actual deviceToken
        }
        else {
            NSMutableDictionary *mutableUpdates = [NSMutableDictionary dictionaryWithDictionary:updates];
            NSString* isGameOver = [mutableUpdates objectForKey:kIsGameOver];
            [mutableUpdates removeObjectForKey:kIsGameOver];
            updatesAsJSON = [jwriter stringWithObject:mutableUpdates];
            dataString = [NSString stringWithFormat:@"lastUpdate=%@&deviceToken=%@&isGameOver=%@", updatesAsJSON, @"b", isGameOver];
            // TODO: faking deviceToken, replace with call to get actual deviceToken
        }
        
        NSString *urlString = [NSString stringWithFormat:@"%@/game/%@/update", kBaseURL, gameID];
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
            
            // downloader error
            if (notification.userInfo) {
                NSError *error = [notification.userInfo objectForKey:kDVDownloaderErrorKey];
                block(error);
            } else {
                NSString *jsonString = [[NSString alloc] initWithData:downloader.receivedData encoding:NSUTF8StringEncoding];
                DLog(@"SERVER response: %@", jsonString);
                NSDictionary *resp = [jsonString JSONValue];
                
                // server error
                if ([resp valueForKey:kDVAPIErrorKey] != nil) {
                    NSString *errorMessage = [[resp objectForKey:kDVAPIErrorKey] objectForKey:kDVAPIErrorMsgKey];
                    NSError *error = [NSError errorWithDomain:kDVAPIWrapperErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(errorMessage, @"")}];
                    block(error);
                } else {
                    block(nil);
                }
            }
            
            [self->connections removeObject:downloader]; // downloader work is done
        }];
        
        [self->observers addObject:observer];
        [downloader.connection start]; // setup to have to start manually
    }
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
    
    // TODO: figure out if I should be removing open connections some other way besides setting to nil
    self->connections = nil;
    self->observers = nil;
}

@end