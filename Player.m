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

// static int _nextPlayer = kDVPlayerOne;

@implementation Player

@synthesize minions = _minions;
@synthesize mode = _mode;
@synthesize numMelons = _numMelonsCollected;
@synthesize numKills = _numKills;
@synthesize numShurikens = _numShurikens;
@synthesize numMissiles = _numMissiles;
@synthesize enemyPlayer = _enemyPlayer;
@synthesize missiles = _missiles;
@synthesize shurikens = _shurikens;
@synthesize carryingChicken = _carryingChicken;
@synthesize ownedChicken = _ownedChicken;
@synthesize score = _score;
@synthesize isCarryingChicken = _isCarryingChicken;
//@synthesize chickenSprite = _chickenSprite;

/*
+(int)nextUniqueID {
    if (_nextPlayer == kDVPlayerOne) {
        _nextPlayer = kDVPlayerTwo;
        return kDVPlayerOne;
    }
    return kDVPlayerTwo;
}
*/
 
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint])
    {
        self.entityType = kEntityTypePlayer;
        self.uniqueID = intID; // [Player nextUniqueID];
//        self->_playerMinionList = [[NSMutableArray alloc] init];
        self->_minions = [[NSMutableDictionary alloc] init];
        self->_missiles = [[NSMutableDictionary alloc] init];
        self->_shurikens = [[NSMutableDictionary alloc] init];
        self.mode = DVPlayerMode_Moving;
        self.isCarryingChicken = NO;
        
        // set Player's initial stats
        [self initStats];
        
        if(self.uniqueID == 1)
            self.sprite = [CCSprite spriteWithFile:@"PlayerGreen.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"PlayerRed.png"];

//        [self setContentSize:self.sprite.boundingBox.size];
        self.sprite.position = spawnPoint;

        // Player spawning is not initially reported (spawning is automatic on both sides on game initialization) - FIX later
//        [self cacheStateForEvent:DVEvent_Spawn];

        [self addChild:self.sprite];
        [self.gameLayer addChild:self];
    }
    return self;
}

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles
{
    if (self = [self initInLayer:layer atSpawnPoint:spawnPoint withUniqueIntID:intID]) {
//        self.uniqueID = intID;
        self.numShurikens = numShurikens;
        self.numMissiles = numMissles;
    }
    return self;
}

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles withKills:(int)numKills withMelons:(int)numMelons
{
    if (self = [self initInLayer:layer atSpawnPoint:spawnPoint withUniqueIntID:intID withShurikens:numShurikens withMissles:numMissles]) {
//        self.uniqueID = intID;
        self.numKills = numKills;
        self.numMelons = numMelons;
    }
    return self;
}

-(void)kill // possibly animate a death then remove this minion
{
//    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
    //myLayer.numKills += 1;
    //[myLayer.hud numKillsChanged:myLayer.numKills];

    self.isDead = YES;
    
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
    
//    [self cacheStateForEvent:DVEvent_Respawn];  // don't cache for now
    
/*
    // need to report on re-appearance
    // record an event entry for spawning
    NSString* activityEntry = [NSString stringWithFormat:@"%d regenerate %@ -1 %d %d",
                               myLayer.timeStepIndex, playerID, (int)position.x, (int)position.y];
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"spawn...%@",activityEntry);
*/
    
}

-(void)initStats
{
    // respawn sound
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds

    self.isDead = NO;
    self.hitPoints = 1;

//    [self cacheStateForEvent:DVEvent_InitStats];  // don't cache for now
    
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d initStats %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    //[Bat uniqueIntIDCounter]
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"initStats...%@",activityEntry);
*/
}

// override has no rotation for Player like Entity
-(void)animateMove:(CGPoint) targetPoint  // will animate a historical move over time interval kTimeStepSeconds
{
    // DON'T call super
    
    // make an action for moving from current point to targetPoint
    //rotate to face the direction of movement
    //    CGPoint diff = ccpSub(targetPoint, self.sprite.position);  // Change to this for multiplay
    //    DLog(@"Starting animateMove for ID %d", self.uniqueID);
    if(targetPoint.x == self.lastPoint.x && targetPoint.y == self.lastPoint.y)
    {
        // the action is to pause the sprite for kReplayTickLengthSeconds time
        id actionStall = [CCActionInterval actionWithDuration:kReplayTickLengthSeconds];  // DEBUG does this work??
        [self.actionsToBePlayed addObject:actionStall];  // change to this for multiplay
        return;
    }
    self.lastPoint = targetPoint;
    
    id actionMove = [CCMoveTo actionWithDuration:kReplayTickLengthSeconds position:targetPoint];
    
    DLog(@"BEFORE push [_actionsToBePlayed count] = %d",[self.actionsToBePlayed count]);
    
    [self.actionsToBePlayed addObject:actionMove];  // change to this for multiplay
    
    DLog(@"AFTER push [_actionsToBePlayed count] = %d",[self.actionsToBePlayed count]);
    
    DLog(@"Move from %f,%f to %f,%f", self.sprite.position.x, self.sprite.position.y, targetPoint.x, targetPoint.y);
        
}

-(void)animateKill:(CGPoint)killPosition
{
//    [super animateKill:killPosition];  // puts any necessary sprint to last location action into the actionsToBePlayed queue
    self.isDead = YES;

    // do NOT call super, since super will remove us from the layer and we will lose minions, etc
    // instead, just re-locate to spawn point and change state variables
    
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

//    self.sprite.opacity = 0;  // 0 - totally transparent, 255 - opaque
    
    // Don't remove the sprite, just re-position back to spawn point (not a MOVE action, will need to register different history
    self.sprite.position = self.spawnPoint;
    
//    self.sprite.opacity = 100;
    // set Player's initial stats
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds
    
    self.isDead = NO;
    self.hitPoints = 1;

}

-(void) draw
{
    [super draw];
    [_carryingChicken draw];
}

-(void) pickupChicken:(Chicken*)chicken  // DEBUG - change this to pass a tag ID for the chicken which is same as ownerID for the Chicken?
{
    self.carryingChicken = chicken;
    self.isCarryingChicken = TRUE;
    //[chicken removeFromParentAndCleanup:YES];
//    [chicken nodeToWorldTransform];
    [self.gameLayer removeChild:self.carryingChicken cleanup:YES];
//    [chicken removeChild:chicken.sprite cleanup:YES];
//    [self setAnchorPoint:self.sprite.position];
//    self.sprite.position = self.sprite.position;
    // first remove chicken's sprite as a child of chicken class (this could seriously fuck shit up)
/*  // THIS WORKS
    CCNode* aNode = [[CCNode alloc] init];
    CCSprite* aSprite = [CCSprite spriteWithFile:@"chickenRed.png"];
    [aNode addChild:aSprite];
    [self.sprite addChild:aNode];
*/
    
//    [chicken removeFromParentAndCleanup:YES];
    // chicken sprite down to chicken node
//    [chicken removeFromParentAndCleanup:YES];
//    chicken.position = [self convertToNodeSpace:chicken.sprite.position];

//    ULog(@"chicken.owner.uniqueID = %d",chicken.owner.uniqueID);

    [self.sprite addChild:self.carryingChicken];
   
    
    //    self->_carryingChicken.sprite.position = [self.gameLayer convertToNodeSpace:self->_carryingChicken.sprite.position];

    
    
/*
    self->_carryingChicken = chicken;
    [_carryingChicken.sprite removeFromParentAndCleanup:YES];
    self->_carryingChicken.sprite.position = [self.gameLayer convertToNodeSpace:self->_carryingChicken.sprite.position];
    [self.sprite addChild:self->_carryingChicken.sprite z:10];
//    [self->_carryingChicken.sprite setPosition:[self.gameLayer convertToNodeSpace:self->_carryingChicken.sprite.position]];
    self->_carryingChicken.sprite.position = self.sprite.position;
*/
}

-(void) dropChicken
{
    // DEBUG - change this to make a tag ID for the chicken which is same as ownerID for the Chicken?
    // this won't work, we'll kill our own sprite. fix by keeping the tag of our picked up chicken
//    [self removeChildByTag:self.carryingChickenTag cleanup:YES];
}


@end
