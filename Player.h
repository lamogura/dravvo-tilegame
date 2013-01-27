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

// change properties if you chane this KVO constants
#define kDVNumMelonsKVO     @"numMelons"
#define kDVNumKillsKVO      @"numKills"
#define kDVNumShurikensKVO  @"numShurikens"
#define kDVNumMisslesKVO    @"numMissiles"

// action modes the player can be in
typedef enum {
    DVPlayerMode_Moving,
    DVPlayerMode_Shooting,
} DVPlayerMode;

@class CoreGameLayer;

@interface Player : EntityNode

@property (nonatomic, readonly) NSMutableArray* minions;
@property (nonatomic, assign) DVPlayerMode mode;

// change related consts if you ever any of these properties used in KVO
@property (nonatomic, assign) int numMelons;
@property (nonatomic, assign) int numKills;
@property (nonatomic, assign) int numShurikens; // FIX should be able just to count objects in array
@property (nonatomic, assign) int numMissiles; // FIX should be able just to count objects in array

// constructors
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withShurikens:(int)numShurikens withMissles:(int)numMissles;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withShurikens:(int)numShurikens withMissles:(int)numMissles withKills:(int)numKills withMelons:(int)numMelons;

@end
