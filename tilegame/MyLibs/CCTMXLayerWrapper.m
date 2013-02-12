//
//  CCCacheableTMXLayer.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/12/13.
//
//

#import "CCTMXLayerWrapper.h"
#import "cocos2d.h"
#import "CoreGameLayer.h"
#import "CCSequence+Helper.h"

@implementation CCTMXLayerWrapper

@synthesize gameLayer = _gameLayer;
@synthesize layerType = _layerType;
@synthesize actionsToBePlayedArray = _actionsToBePlayedArray;
@synthesize tmxLayer = _tmxLayer;

-(id) initWithlayerFromTileMap:(CCTMXTiledMap*)tileMap InCoreGameLayer:(CoreGameLayer *)gameLayer OfType:(LayerType)layerType
{
 	if (self=[super init])
 	{
        [super onEnter];
        self.actionsToBePlayedArray = [[NSMutableArray alloc] init];
        
        self.gameLayer = gameLayer;
        switch (layerType) {
            case LayerType_Background:
            self.tmxLayer = [tileMap layerNamed:@"Background"];
            self.layerType = kLayerTypeBackground;
            break;
        case LayerType_Foreground:
            self.tmxLayer = [tileMap layerNamed:@"Foreground"];
            self.layerType = kLayerTypeForeground;
            break;
        case LayerType_Destruction:
            self.tmxLayer = [tileMap layerNamed:@"Destruction"];
            self.layerType = kLayerTypeDestruction;
            break;
        case LayerType_Meta:
            self.tmxLayer = [tileMap layerNamed:@"Meta"];
            self.layerType = kLayerTypeMeta;
            break;
        default:
            NSAssert(false, @"somehow bad layerType passed into switch");
            break;
        }
 	}
 	return self;
}


-(void) removeTileAt:(CGPoint)tileCoordinate
{
 	[self.tmxLayer removeTileAt: tileCoordinate];
 	[self cacheStateForEvent:DVEvent_RemoveTile atTileCoordinate:tileCoordinate];
}

-(void)cacheStateForEvent:(DVEventType)event atTileCoordinate:(CGPoint)tileCoordinate
{
    // 	{"EntityType":"bat","EntityID":2,"EventType":1,"CoordX":371.06390380859375,"CoordY":1220.031005859375,"TimeStepIndex":14,"OwnerID":1}
 	
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

-(void)animateRemoveTileAtTileCoordinate:(CGPoint)tileCoordinate afterDelay:(ccTime) delay 	// will animate a historical move over time interval kTimeStepSeconds
{
 	NSMutableArray* actionsToBePlayed = [[NSMutableArray alloc] init];
 	// the action is to pause the sprite for kReplayTickLengthSeconds time
 	id actionStall = [CCActionInterval actionWithDuration:delay]; // DEBUG does this work??
 	
 	id actionRemoveTile = [CCCallBlock actionWithBlock:^(void){
        [self.tmxLayer removeTileAt:tileCoordinate];
 	}];
 	
 	[actionsToBePlayed addObject:actionStall]; // change to this for multiplay
 	[actionsToBePlayed addObject:actionRemoveTile];
    
 	[self.actionsToBePlayedArray addObject:actionsToBePlayed];
    
}

-(void)playActionsInSequence // Adds all the actions in the NSMutableArray to a CCSequence and plays them
{
    // 	if([self.actionsToBePlayed count] == 0)
    // 	{
    // 			selfDLog(@"No actions to be played. Returning...");
    // 			selfreturn;
    // 	}
 	DLog(@"Playing actions sequence!!!");
 	
 	// cycyle through actionsto be played array playing actions to be played
 	for(NSMutableArray* actionsToBePlayed in self.actionsToBePlayedArray)
 	{
        [self runAction:[CCSequence actionMutableArray:actionsToBePlayed]];
 	}
 	
 	
 	// 	_numAnimationsPlaying++;
 	// 	CCSequence *seq = [CCSequence actionMutableArray:_actionsToBePlayed];
 	
 	// 	[self.sprite runAction:[CCSequence actionMutableArray:_actionsToBePlayed]];
 	
 	// increment CoreGameLayer's animations running counter
 	// 	CoreGameLayer* theLayer = (CoreGameLayer *) self.gameLayer;
 	
 	// push a callback action on the actionMutableArray
 	// 	id actionCallFunc = [CCCallFunc actionWithTarget:theLayer selector:@selector(tryEnemyPlayback)];
 	
 	// 	[_actionsToBePlayed addObject:actionCallFunc]; // change to this for multiplay
 	
 	
 	DLog(@"Finished pushing actions sequence!!!");
 	// 	[self.sprite runAction:actionMove];
}

@end