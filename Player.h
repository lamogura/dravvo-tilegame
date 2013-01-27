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

// action modes the player can be in
typedef enum {
    DVPlayerMode_Moving,
    DVPlayerMode_Shooting,
} DVPlayerMode;

@class CoreGameLayer;

@interface Player : EntityNode

@property (nonatomic, readonly) NSMutableArray* minions;
@property (nonatomic, assign) DVPlayerMode mode;

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;

@end
