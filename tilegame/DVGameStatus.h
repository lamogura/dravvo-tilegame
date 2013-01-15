//
//  DVTextMessage.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVGameStatus : NSObject

@property (nonatomic, copy) NSString *dbID;
@property (nonatomic, retain) NSDate *createdAt;

@property (nonatomic, copy) NSString *deviceToken;
@property (nonatomic, copy) NSString *lastUpdate;
@property (nonatomic, assign) BOOL isGameOver;

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithJSONString:(NSString *)jsonString;

@end
