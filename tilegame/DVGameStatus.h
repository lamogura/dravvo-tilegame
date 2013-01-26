//
//  DVTextMessage.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVGameStatus : NSObject

@property (nonatomic, copy) NSString *gameID;
@property (nonatomic, retain) NSDate *createdAt;

@property (nonatomic, copy) NSString *nextTurn;
@property (nonatomic, retain) NSArray *lastUpdates;
@property (nonatomic, assign) BOOL isGameOver;

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithJSONString:(NSString *)jsonString;
- (id)initWithTurn:(NSString *)turn;

@end