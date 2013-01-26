//
//  Player.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import "Player.h"
#import "HelloWorldLayer.h"
#import "cocos2d.h"
#import "GameConstants.h"
#import "DVMacros.h"
#import "SimpleAudioEngine.h"

@implementation Player

@synthesize myLayer, isAlive, sprite, playerID, hitPoints, playerMinionList, initialSpawnPoint, historicalEventsList_local;

-(id)initWithLayer:(HelloWorldLayer*) layer andPlayerID:(NSString*)plyrID andSpawnAt:(CGPoint) spawnPoint;
{
    self = [super init];
    if(self)
    {
        playerID = plyrID;
        initialSpawnPoint = spawnPoint;

        playerMinionList = [[NSMutableArray alloc] init];
        // store the layer we belong to - not sure if this is needed or not
        myLayer = layer;
        
//        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];  // preload creature sounds

        // set Player's initial stats
        [self initStats];
        
        sprite = [CCSprite spriteWithFile:@"Player.png"];
        sprite.position = initialSpawnPoint;

        // NEW
        // Dictionary constructor is delimited with nil
        
        NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex,  @"spawn", kDVHistKey_Action, playerID, kDVHistKey_OwnerID, playerID, kDVHistKey_EntityType, [NSNumber numberWithInt:-1], kDVHistKey_EntityNumber, [NSNumber numberWithFloat:sprite.position.x], kDVHistKey_CoordX, [NSNumber numberWithFloat:sprite.position.y], kDVHistKey_CoordY, nil];
        // Now put this dictionary onto the object's NSMuttableArray
        [historicalEventsList_local addObject:activityDictionary];
        DLog(@"spawn...%@",activityDictionary);

/*
        // record an event entry for spawning
        NSString* activityEntry = [NSString stringWithFormat:@"%d spawn %@ -1 %d %d",
                                   myLayer.timeStepIndex, playerID, (int)sprite.position.x, (int)sprite.position.y];
        [historicalEventsList_local addObject:activityEntry];
        DLog(@"spawn...%@",activityEntry);
*/
        [self addChild:sprite];
        // is this enough to display it?
        
        [myLayer addChild:self];
    }
    return self;
}

-(void)sampleCurrentPosition
{
    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex,  @"move", kDVHistKey_Action, playerID, kDVHistKey_OwnerID, playerID, kDVHistKey_EntityType, [NSNumber numberWithInt:-1], kDVHistKey_EntityNumber,  [NSNumber numberWithFloat:sprite.position.x], kDVHistKey_CoordX, [NSNumber numberWithFloat:sprite.position.y], kDVHistKey_CoordY, nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [historicalEventsList_local addObject:activityDictionary];
    DLog(@"sample...%@",activityDictionary);

/*
    // generate a "move" event string entry from last point to current point with a time differential of kPlaybackTickLengthSeconds
    NSString* activityEntry = [NSString stringWithFormat:@"%d move %@ -1 %d %d",
                               myLayer.timeStepIndex, playerID, (int)sprite.position.x, (int)sprite.position.y];
    
    [historicalEventsList_local addObject:activityEntry];
    DLog(@"sample...%@",activityEntry);
*/
}

-(void)wound:(int) hpLost
{
    hitPoints -= hpLost;
    // we send hpLost in place of the x-coordinate integer holder
    

    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex,  @"wound", kDVHistKey_Action, playerID, kDVHistKey_OwnerID, playerID, kDVHistKey_EntityType, [NSNumber numberWithInt:-1], kDVHistKey_EntityNumber, [NSNumber numberWithInt:hpLost], kDVHistKey_CoordX, [NSNumber numberWithInt:-1], kDVHistKey_CoordY,  nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [historicalEventsList_local addObject:activityDictionary];
    DLog(@"wound...%@",activityDictionary);
    
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d wound %@ -1 %d -1",
                               myLayer.timeStepIndex, playerID, hpLost];
    //[Bat uniqueIntIDCounter]
    
    [historicalEventsList_local addObject:activityEntry];
    DLog(@"wound...%@",activityEntry);
*/
}
-(void)kill // possibly animate a death then remove this minion
{
//    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
    //myLayer.numKills += 1;
    //[myLayer.hud numKillsChanged:myLayer.numKills];
    
    isAlive = NO;
    
    // kill sound
//    DMPlayerDies.m4r
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMPlayerDies.m4r"];  // preload creature sounds

    // now load the dead image
    // Don't keep a handle for it, let it remain there until the game is over (messy field of battle
    CCSprite* deadSprite = [CCSprite spriteWithFile:@"bloodSplat.png"];
    deadSprite.opacity = 175; // 0 to 255, transparent to opaque
    deadSprite.position = sprite.position;
    
    deadSprite.scaleX = 0.50;
    deadSprite.scaleY = 0.50;

    [self addChild:deadSprite];
    
    id scaleUpAction = [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:3.0 scaleY:3.0] rate:1.0];
    [deadSprite runAction:scaleUpAction];

    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex, @"kill", kDVHistKey_Action,  playerID, kDVHistKey_OwnerID, playerID, kDVHistKey_EntityType, [NSNumber numberWithInt:-1], kDVHistKey_EntityNumber, [NSNumber numberWithInt:-1], kDVHistKey_CoordX, [NSNumber numberWithInt:-1], kDVHistKey_CoordY, nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [historicalEventsList_local addObject:activityDictionary];
    DLog(@"kill...%@",activityDictionary);
 
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d kill %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    
    [historicalEventsList_local addObject:activityEntry];
    DLog(@"kill...%@",activityEntry);
*/
    // regenerate but remain isAlive = NO until start of next round
    sprite.opacity = 0;  // 0 - totally transparent, 255 - opaque

    // Don't remove the sprite, just re-position back to spawn point (not a MOVE action, will need to register different history
    [self regenerate];
    
}

// called in HelloWorldLayer after if(player.isAlive == NO) { [player regenerate] }
-(void)regenerate
{
    sprite.position = initialSpawnPoint;
    
    sprite.opacity = 100;
    // set Player's initial stats
    [self initStats];
    
    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex, @"regenerate", kDVHistKey_Action, playerID, kDVHistKey_OwnerID, playerID, kDVHistKey_EntityType, [NSNumber numberWithInt:-1], kDVHistKey_EntityNumber, [NSNumber numberWithFloat:sprite.position.x], kDVHistKey_CoordX, [NSNumber numberWithFloat:sprite.position.y], kDVHistKey_CoordY,  nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [historicalEventsList_local addObject:activityDictionary];
    DLog(@"regenerate...%@",activityDictionary);
     
/*
    // need to report on re-appearance
    // record an event entry for spawning
    NSString* activityEntry = [NSString stringWithFormat:@"%d regenerate %@ -1 %d %d",
                               myLayer.timeStepIndex, playerID, (int)sprite.position.x, (int)sprite.position.y];
    [historicalEventsList_local addObject:activityEntry];
    DLog(@"spawn...%@",activityEntry);
*/
    
}

-(void)initStats
{
    // respawn sound
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds

    isAlive = YES;
    self.hitPoints = 1;

    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex, @"initStats", kDVHistKey_Action, playerID, kDVHistKey_OwnerID, playerID, kDVHistKey_EntityType, [NSNumber numberWithInt:-1], kDVHistKey_EntityNumber, [NSNumber numberWithInt:-1], kDVHistKey_CoordX, [NSNumber numberWithInt:-1], kDVHistKey_CoordY,  nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [historicalEventsList_local addObject:activityDictionary];
    DLog(@"initStats...%@",activityDictionary);
 
 
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d initStats %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    //[Bat uniqueIntIDCounter]
    
    [historicalEventsList_local addObject:activityEntry];
    DLog(@"initStats...%@",activityEntry);
*/
}

-(void) performHistoryAtTimeStepIndex:(int) theTimeStepIndex
{
    [super performHistoryAtTimeStepIndex:theTimeStepIndex]; // maybe not necessary
    
    // now cycle through the historicalEventsList_local array, pull all dictionaries for
    // if object at the key kDVHistKey_TimeStepIndex == "theTimeStepIndex", then push the action to the actionMutableArray array so actions run in sequence
    // without killing the previous one
    
}


@end
