//
//  Player.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//
#import <Foundation/Foundation.h>
#import "EntityNode.h"
#import "CoreGameLayer.h"

#define kDVPlayerOne 1
#define kDVPlayerTwo 2

@class CoreGameLayer;

@interface Player : EntityNode

@property (nonatomic, readonly) NSMutableArray* playerMinionList;

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;

//-(void)sampleCurrentPosition;
//-(void)wound:(int) hpLost;
//-(void)kill; // possibly animate a death then remove this minion
//-(void)regenerate;
//-(void)initStats;
//-(void) performHistoryAtTimeStepIndex:(int) theTimeStepIndex;

@end
