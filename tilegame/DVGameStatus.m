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

@synthesize dbID;
@synthesize createdAt;

@synthesize deviceToken;
@synthesize lastUpdate;
@synthesize isGameOver;

- (id)initWithDictionary:(NSDictionary *) dict {
    self = [super init];
    if (self) {
        self.dbID        = [dict objectForKey:@"_id"];
        self.deviceToken = [dict objectForKey:@"deviceToken"];
        self.lastUpdate  = [dict objectForKey:@"lastUpdate"];
        self.isGameOver  = [@"true" isEqualToString:[dict objectForKey:@"isGameOver"]] ? TRUE : FALSE;
        
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
