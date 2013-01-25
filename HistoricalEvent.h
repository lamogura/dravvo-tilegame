//
//  HistoricalEvent.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/25/13.
//
//

#import <Foundation/Foundation.h>

@interface HistoricalEvent : NSObject

@property (nonatomic, assign) int timeStepIndex;
@property (nonatomic, strong) NSString* action;
@property (nonatomic, strong) NSString* entityType;
@property (nonatomic, strong) NSString* entityIDNumber;
@property (nonatomic, assign) int coordX;
@property (nonatomic, assign) int coordY;

@end
