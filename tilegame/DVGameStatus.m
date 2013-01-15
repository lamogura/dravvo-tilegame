//
//  DVTextMessage.m
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "DVGameStatus.h"
#import "SBJson.h"

@implementation DVGameStatus

@synthesize gameID;
@synthesize createdAt;

@synthesize nextTurn;
@synthesize lastUpdate;
@synthesize isGameOver;

- (id)initWithDictionary:(NSDictionary *) dict {
    self = [super init];
    if (self) {
        self.gameID = [dict objectForKey:@"_id"];
        self.nextTurn = [dict objectForKey:@"nextTurn"];
        
        if ([dict objectForKey:@"lastUpdate"] != [NSNull null]) {
            int x;
        }
        
        self.isGameOver  = [@"true" isEqualToString:[dict objectForKey:@"isGameOver"]] ? YES : NO;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
        NSDate *date;
        [formatter getObjectValue:&date forString:[dict objectForKey:@"createdAt"] range:nil error:nil];
        self.createdAt = date;
    }
    return self;
}

- (id)initWithJSONString:(NSString *)jsonString {
    return [[DVGameStatus alloc] initWithDictionary:[jsonString JSONValue]];
}

@end
