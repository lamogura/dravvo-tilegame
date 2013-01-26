//
//  Bat.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//

#import "Bat.h"
#import "GameConstants.h"
#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "SimpleAudioEngine.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"

static int theUniqueIntIDCounter = -1;

@implementation Bat

@synthesize myLayer, sprite, hitPoints, speedInPixelsPerSec, behavior, previousPosition, ownershipPlayerID, entityType, uniqueIntID;

+(int)uniqueIntIDCounter  // static function for providing unique integer IDs to each new instance of each particular entity kind
{
//    static int initializeIntIDCounter = 0;  // this is only run once, otherwise, a call to this function will return the uniqueIntIDCounter int value
    return theUniqueIntIDCounter;
}

// required METHODS
// init
-(id)initWithLayer:(CoreGameLayer*) layer andSpawnAt:(CGPoint) spawnPoint withBehavior:(int) initBehavior withPlayerOwner:(NSString*) ownerPlayerID;
{
    self = [super init];
    if(self)
    {
        entityType = @"bat";
        // Assign a uniqueIntIDCounter
        theUniqueIntIDCounter++;
     
        uniqueIntID = theUniqueIntIDCounter;
        ownershipPlayerID = ownerPlayerID;
        previousPosition = spawnPoint;
        
        // store the layer we belong to - not sure if this is needed or not
        myLayer = layer;
        behavior = initBehavior;

        // set bat's stats
        self.hitPoints = 1;
        self.speedInPixelsPerSec = 33;
    
        sprite = [CCSprite spriteWithFile:@"bat2.png"];
        sprite.position = spawnPoint;
        
        [self addChild:sprite];
        // is this enough to display it?
        
        // record an event entry for spawning
        // Should look like:  P1_bat
//        NSMutableString* entity = @"bat";
        

//        ownerAndEntityID = [ownershipPlayerID stringByAppendingFormat:@"bat"];
//        ownerAndEntityID = [ownershipPlayerID stringByAppendingString:@"bat"];
//        [ownershipPlayerID stringByAppendingString:@"bat"];

        NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex,
                                            @"spawn", kDVHistKey_Action,
                                            ownershipPlayerID, kDVHistKey_OwnerID,
                                            entityType, kDVHistKey_EntityType,
                                            [NSNumber numberWithInt:uniqueIntID], kDVHistKey_EntityNumber,
                                            [NSNumber numberWithFloat:sprite.position.x], kDVHistKey_CoordX,
                                            [NSNumber numberWithFloat:sprite.position.y], kDVHistKey_CoordY, nil];
        // Now put this dictionary onto the object's NSMuttableArray
        [self.historicalEventsList_local addObject:activityDictionary];
        DLog(@"spawn...%@",activityDictionary);
        
        [myLayer addChild:self];
        
        //[self takeActions];
    }
    return self;
}

// for sampling during real actions
-(void)sampleCurrentPosition //:(int) theUniqueIntID // this should be called (callbacked) once every kTimeStepSeconds for later animation on player2's side
{
    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex,  @"move", kDVHistKey_Action, ownershipPlayerID, kDVHistKey_OwnerID, entityType, kDVHistKey_EntityType, [NSNumber numberWithInt:uniqueIntID], kDVHistKey_EntityNumber,  [NSNumber numberWithFloat:sprite.position.x], kDVHistKey_CoordX, [NSNumber numberWithFloat:sprite.position.y], kDVHistKey_CoordY, nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [self.historicalEventsList_local addObject:activityDictionary];
    DLog(@"sample...%@",activityDictionary);

/*
    // generate a "move" event string entry from last point to current point with a time differential of kPlaybackTickLengthSeconds
    NSString* activityEntry = [NSString stringWithFormat:@"%d aniMove %@ %d %d %d",
                               myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID, (int)sprite.position.x, (int)sprite.position.y];

    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"sample...%@",activityEntry);
*/
}


// state changes like decreasing HP or killing a creature
-(void)wound:(int) hpLost
{
    hitPoints -= hpLost;
    // we send hpLost in place of the x-coordinate integer holder

    // Dictionary constructor is delimited with nil
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex,  @"wound", kDVHistKey_Action, ownershipPlayerID, kDVHistKey_OwnerID, entityType, kDVHistKey_EntityType, [NSNumber numberWithInt:uniqueIntID], kDVHistKey_EntityNumber, [NSNumber numberWithInt:hpLost], kDVHistKey_CoordX, [NSNumber numberWithInt:-1], kDVHistKey_CoordY,  nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [self.historicalEventsList_local addObject:activityDictionary];
    DLog(@"wound...%@",activityDictionary);
    
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d wound %@ %d %d -1",
                               myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID, hpLost];
    //[Bat uniqueIntIDCounter]
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"wound...%@",activityEntry);
*/

//  There's concurrency problems here so we have to wait for kill to be called from HelloWorldLayer first FIX
//    if(hitPoints < 1)
//        [self kill];
}
-(void)kill // possibly animate a death then remove this minion
{
    // since we instantly erase and remove this bat here, audio won't have a chance to play. we have to do it in HelloWorldLayer logic
//    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
//    [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombie.m4ra"];

    //myLayer.numKills += 1;
    //[myLayer.hud numKillsChanged:myLayer.numKills];

    // remove the sprite as a CCNode and cleanup
  
    NSDictionary* activityDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:myLayer.timeStepIndex], kDVHistKey_TimeStepIndex, @"kill", kDVHistKey_Action,  ownershipPlayerID, kDVHistKey_OwnerID, entityType, kDVHistKey_EntityType, [NSNumber numberWithInt:uniqueIntID], kDVHistKey_EntityNumber, [NSNumber numberWithInt:-1], kDVHistKey_CoordX, [NSNumber numberWithInt:-1], kDVHistKey_CoordY, nil];
    // Now put this dictionary onto the object's NSMuttableArray
    [self.historicalEventsList_local addObject:activityDictionary];
    DLog(@"kill...%@",activityDictionary);


    [self removeChild:sprite cleanup:YES];
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d kill %@ %d -1 -1",
                               myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID];
    //[Bat uniqueIntIDCounter]
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"kill...%@",activityEntry);
*/

    // remove this bat from the layer's list
    // THIS MIGHT BE FUCKED FIX // not sure if it's OK to remove ourselves from the layer's array
    // this won't work because an element of the array will be deleted while the array is being run through
//    [myLayer.bats removeObject:self];
//    [myLayer removeChild:self cleanup:YES];
}

-(void)realUpdate
{
    // Bat moves toward the player, in the test case
    // calculate duration of how far bat can fly during kTickLengthSeconds time
    // travel there and then do nothing until the next update is called
    
    // Actions depend on behavior setting
    // behavior must = kBehavior_idle in the case of re-playing opponent's last actions
    // begin doing shit with this entity (moving, attacking, etc)
    switch (behavior) {
        case kBehavior_idle:
            // do nothing but idle at sprite's location
            break;
        case kBehavior_default:
        {
            //rotate to face the player
            
            CGPoint diff = ccpSub(myLayer.player.sprite.position, sprite.position);
            float angleRadians = atanf((float)diff.y / (float)diff.x);
            float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
            float cocosAngle = -1 * angleDegrees;
            if(diff.x < 0)
                cocosAngle += 180;
            sprite.rotation = cocosAngle;
            
            // 10 pixels per 0.3 seconds -> speed = 33 pixels / second
            int distancePixels = (int) (speedInPixelsPerSec * kTickLengthSeconds);
//            ccTime actualDuration = (float) distancePixels / speedInPixelsPerSec; //  0.3; //  v = d / t; t = d / v

            //            actualDuration = 0.3;
            // create the actions
            // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
            // ccpNormalize calculates a unit vector given 2 point coordinates,...
            // and gives a hypotenous of length 1 with appropriate x,y
            //            id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(myLayer.player.position,sprite.position)), 10)];
            id actionMove = [CCMoveBy actionWithDuration:kTickLengthSeconds position:ccpMult(ccpNormalize(ccpSub(myLayer.player.sprite.position,sprite.position)), distancePixels)];
            // callback to this method again! If the entity has changed it's behavior, then a different case will be implemented
//            id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(takeActions)];
//            [sprite runAction:[CCSequence actions:actionMove, nil]];
            [sprite runAction:actionMove];
        }
            
            break;
        default:
            break;
    }
    
}

-(void)realSetBehaviour:(int) newBeahavior
{
    
}

-(void)realMove:(CGPoint) targetPoint
{
    
}

-(void)realExplode:(CGPoint) targetPoint
{
    
}



// for later animation re-play on player2's side
// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
-(void)aniMove:(CGPoint) targetPoint  // will animate a historical move over time interval kTimeStepSeconds
{
    
}
-(void)aniExplode:(CGPoint) targetPoint  // animate it exploding
{
    
}

-(void) takeActions
{
    // Actions depend on behavior setting
    // behavior must = kBehavior_idle in the case of re-playing opponent's last actions
    // begin doing shit with this entity (moving, attacking, etc)
    switch (behavior) {
        case kBehavior_idle:
            // do nothing but idle at sprite's location
            break;
        case kBehavior_default:
        {
            //rotate to face the player
            
            CGPoint diff = ccpSub(myLayer.player.sprite.position, sprite.position);
            float angleRadians = atanf((float)diff.y / (float)diff.x);
            float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
            float cocosAngle = -1 * angleDegrees;
            if(diff.x < 0)
                cocosAngle += 180;
            sprite.rotation = cocosAngle;
            
            // 10 pixels per 0.3 seconds -> speed = 33 pixels / second
            int distancePixels = 10;
            ccTime actualDuration = (float) distancePixels / speedInPixelsPerSec; //  0.3; //  v = d / t; t = d / v
            
//            actualDuration = 0.3;
            // create the actions
            // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
            // ccpNormalize calculates a unit vector given 2 point coordinates,...
            // and gives a hypotenous of length 1 with appropriate x,y
//            id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(myLayer.player.position,sprite.position)), 10)];
            id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(myLayer.player.sprite.position,sprite.position)), distancePixels)];
            // callback to this method again! If the entity has changed it's behavior, then a different case will be implemented
            id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(takeActions)];
            [sprite runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
        }

            break;
        default:
            break;
    }
    
}

-(void) performHistoryAtTimeStepIndex:(int) theTimeStepIndex
{
    [super performHistoryAtTimeStepIndex:theTimeStepIndex]; // maybe not necessary
    
    // now cycle through the self.historicalEventsList_local array, pull all dictionaries for
    // if object at the key kDVHistKey_TimeStepIndex == "theTimeStepIndex", then push the action to the actionMutableArray array so actions run in sequence
    // without killing the previous one

}


@end

