//
//  CCCacheableTMXLayer.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/12/13.
//
//

#import "CCCacheableTMXLayer.h"
#import "cocos2d.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"
#import "CCSequenceHelper.h"

@implementation CCCacheableTMXLayer

@synthesize gameLayer = _gameLayer;
@synthesize layerType = _layerType;
@synthesize actionsToBePlayed = _actionsToBePlayed;

+(CCCacheableTMXLayer *) layerFromCCTMXLayer:(CCTMXLayer *)layer InCoreGameLayer:(CoreGameLayer *)gameLayer OfType:(LayerType)layerType
{
    CCCacheableTMXLayer* cachableLayer = (CCCacheableTMXLayer *)layer;
    cachableLayer.gameLayer = gameLayer;
    switch (layerType) {
        case LayerType_Background:
            cachableLayer.layerType = kLayerTypeBackground;
            break;
        case LayerType_Foreground:
            cachableLayer.layerType = kLayerTypeForeground;
            break;
        case LayerType_Destruction:
            cachableLayer.layerType = kLayerTypeDestruction;
            break;
        case LayerType_Meta:
            cachableLayer.layerType = kLayerTypeMeta;
            break;
            
        default:
            NSAssert(false, @"somehow bad layerType passed into switch");
            break;
    }
    return cachableLayer;
}

-(void) removeTileAt:(CGPoint)tileCoordinate
{
    [super removeTileAt: tileCoordinate];
    [self cacheStateForEvent:DVEvent_RemoveTile atTileCoordinate:tileCoordinate];
}

-(void)cacheStateForEvent:(DVEventType)event atTileCoordinate:(CGPoint)tileCoordinate
{
//    {"EntityType":"bat","EntityID":2,"EventType":1,"CoordX":371.06390380859375,"CoordY":1220.031005859375,"TimeStepIndex":14,"OwnerID":1}
    
    DLog(@"cacheStateForEvent...");
    
    CoreGameLayer* layer = (CoreGameLayer *)self.gameLayer;
    NSMutableDictionary* eventData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:layer.timeStepIndex], kDVEventKey_TimeStepIndex,
                                      self.layerType, kDVEventKey_EntityOrLayerType,
                                      [NSNumber numberWithInt:0], kDVEventKey_UniqueID,
                                      [NSNumber numberWithInt:event], kDVEventKey_EventType,
                                      [NSNumber numberWithFloat:tileCoordinate.x], kDVEventKey_CoordX,
                                      [NSNumber numberWithFloat:tileCoordinate.y], kDVEventKey_CoordY,
                                      nil];
    switch (event) {
        case DVEvent_RemoveTile:
        default:
        
        break;
    }
    [[EntityNode CompleteEventHistory] addObject:eventData];
}

-(void)animateRemoveTileAtTileCoordinate:(CGPoint)tileCoordinate afterDelay:(ccTime) delay   // will animate a historical move over time interval kTimeStepSeconds
{
    // the action is to pause the sprite for kReplayTickLengthSeconds time
    id actionStall = [CCActionInterval actionWithDuration:delay];  // DEBUG does this work??
    
    id actionAppear = [CCCallBlock actionWithBlock:^(void){
        [self removeTileAt:tileCoordinate];
    }];
    
    [self.actionsToBePlayed addObject:actionStall];  // change to this for multiplay
    [self.actionsToBePlayed addObject:actionAppear];

}

-(void)playActionsInSequence  // Adds all the actions in the NSMutableArray to a CCSequence and plays them
{
    if([self.actionsToBePlayed count] == 0)
    {
        DLog(@"No actions to be played. Returning...");
        return;
    }
    DLog(@"Playing actions sequence!!!");
    //    _numAnimationsPlaying++;
    //    CCSequence *seq = [CCSequence actionMutableArray:_actionsToBePlayed];
    
    //    [self.sprite runAction:[CCSequence actionMutableArray:_actionsToBePlayed]];
    
    // increment CoreGameLayer's animations running counter
    //    CoreGameLayer* theLayer = (CoreGameLayer *) self.gameLayer;
    
    // push a callback action on the actionMutableArray
    //    id actionCallFunc = [CCCallFunc actionWithTarget:theLayer selector:@selector(tryEnemyPlayback)];
    
    //    [_actionsToBePlayed addObject:actionCallFunc];  // change to this for multiplay
    
    [self runAction:[CCSequenceHelper actionMutableArray:self.actionsToBePlayed]];
    
    DLog(@"Finished pushing actions sequence!!!");
    //    [self.sprite runAction:actionMove];
}

@end
