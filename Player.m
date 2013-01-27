//
//  Player.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import "Player.h"
#import "CoreGameLayer.h"
#import "cocos2d.h"
#import "GameConstants.h"
#import "DVMacros.h"
#import "SimpleAudioEngine.h"

static int _nextPlayer = kDVPlayerOne;

@implementation Player

@synthesize minions = _playerMinionList;
@synthesize mode = _mode;

+(int)nextUniqueID {
    if (_nextPlayer == kDVPlayerOne) {
        _nextPlayer = kDVPlayerTwo;
        return kDVPlayerOne;
    }
    return kDVPlayerTwo;
}

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint])
    {
        self.uniqueID = [Player nextUniqueID];
        self->_playerMinionList = [[NSMutableArray alloc] init];
        self.mode = DVPlayerMode_Moving;
        
        // set Player's initial stats
        [self initStats];
        
        self.sprite = [CCSprite spriteWithFile:@"Player.png"];
        self.sprite.position = spawnPoint;

        [self cacheStateForEvent:DVEvent_Spawn];

        [self addChild:self.sprite];
        [self.gameLayer addChild:self];
    }
    return self;
}

-(void)kill // possibly animate a death then remove this minion
{
//    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
    //myLayer.numKills += 1;
    //[myLayer.hud numKillsChanged:myLayer.numKills];
    
    self.isAlive = NO;
    
    // kill sound
//    DMPlayerDies.m4r
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMPlayerDies.m4r"];  // preload creature sounds

    // now load the dead image
    // Don't keep a handle for it, let it remain there until the game is over (messy field of battle
    CCSprite* deadSprite = [CCSprite spriteWithFile:@"bloodSplat.png"];
    deadSprite.opacity = 175; // 0 to 255, transparent to opaque
    deadSprite.position = self.sprite.position;
    
    deadSprite.scaleX = 0.50;
    deadSprite.scaleY = 0.50;

    [self addChild:deadSprite];
    
    id scaleUpAction = [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:3.0 scaleY:3.0] rate:1.0];
    [deadSprite runAction:scaleUpAction];

    [self cacheStateForEvent:DVEvent_Kill];
 
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d kill %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"kill...%@",activityEntry);
*/
    // regenerate but remain isAlive = NO until start of next round
    self.sprite.opacity = 0;  // 0 - totally transparent, 255 - opaque

    // Don't remove the sprite, just re-position back to spawn point (not a MOVE action, will need to register different history
    [self regenerate];
    
}

// called in HelloWorldLayer after if(player.isAlive == NO) { [player regenerate] }
-(void)regenerate
{
    self.sprite.position = self.spawnPoint;
    
    self.sprite.opacity = 100;
    // set Player's initial stats
    [self initStats];
    
    [self cacheStateForEvent:DVEvent_Respawn];
    
/*
    // need to report on re-appearance
    // record an event entry for spawning
    NSString* activityEntry = [NSString stringWithFormat:@"%d regenerate %@ -1 %d %d",
                               myLayer.timeStepIndex, playerID, (int)sprite.position.x, (int)sprite.position.y];
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"spawn...%@",activityEntry);
*/
    
}

-(void)initStats
{
    // respawn sound
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds

    self.isAlive = YES;
    self.hitPoints = 1;

    [self cacheStateForEvent:DVEvent_InitStats];
    
 
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d initStats %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    //[Bat uniqueIntIDCounter]
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"initStats...%@",activityEntry);
*/
}

@end
