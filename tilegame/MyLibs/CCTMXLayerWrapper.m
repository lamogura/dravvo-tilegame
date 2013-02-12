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

-(id) initFromTileMap:(CCTMXTiledMap*)tileMap inCoreGameLayer:(CoreGameLayer *)gameLayer layerType:(LayerType)layerType
{
 	if (self=[super init])
 	{
        [super onEnter]; // enable actions to be played
        
        _actionsToBePlayedArray = [[NSMutableArray alloc] init];
        self.gameLayer = gameLayer;
        
        switch (layerType)
        {
            case LayerType_Background:
            self.tmxLayer = [tileMap layerNamed:kLayerName_Background];
            self.layerType = kLayerName_Background;
            break;
                
        case LayerType_Foreground:
            self.tmxLayer = [tileMap layerNamed:kLayerName_Foreground];
            self.layerType = kLayerName_Foreground;
            break;
                
        case LayerType_Destruction:
            self.tmxLayer = [tileMap layerNamed:kLayerName_Destruction];
            self.layerType = kLayerName_Destruction;
            break;
                
        case LayerType_Meta:
            self.tmxLayer = [tileMap layerNamed:kLayerName_Meta];
            self.layerType = kLayerName_Meta;
            break;
                
        default:
            ULog(@"Unknown layerType passed to switch");
            break;
        }
 	}
 	return self;
}


-(void) removeTileAt:(CGPoint)tileCoordinate
{
 	[self cacheStateForEvent:DVEvent_RemoveTile atTileCoordinate:tileCoordinate];

 	[self.tmxLayer removeTileAt:tileCoordinate];
}

-(void) cacheStateForEvent:(DVEventType)event atTileCoordinate:(CGPoint)tileCoordinate
{
    // 	{"EntityType":"bat","EntityID":2,"EventType":1,"CoordX":371.06390380859375,"CoordY":1220.031005859375,"TimeStepIndex":14,"OwnerID":1}
 	
 	DLog(@"cacheStateForEvent type:%d coordX:%f coordY:%f", event, tileCoordinate.x, tileCoordinate.y);
    
 	NSMutableDictionary* eventData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:self.gameLayer.timeStepIndex], kDVEventKey_TimeStepIndex,
                                      self.layerType, kDVEventKey_EntityOrLayerType,
                                      [NSNumber numberWithInt:0], kDVEventKey_UniqueID,
                                      [NSNumber numberWithInt:event], kDVEventKey_EventType,
                                      [NSNumber numberWithFloat:tileCoordinate.x], kDVEventKey_CoordX,
                                      [NSNumber numberWithFloat:tileCoordinate.y], kDVEventKey_CoordY,
                                      nil];

 	[[EntityNode sharedEventHistory] addObject:eventData];
}

// will animate a historical move over time interval kTimeStepSeconds
-(void)animateRemoveTileAtTileCoordinate:(CGPoint)tileCoordinate afterDelay:(ccTime) delay
{
 	// the action is to pause the sprite for kReplayTickLengthSeconds time
 	id actionStall = [CCActionInterval actionWithDuration:delay]; // DEBUG does this work??
 	
 	id actionRemoveTile = [CCCallBlock actionWithBlock:^(void)
    {
        [self.tmxLayer removeTileAt:tileCoordinate];
 	}];
 	
    // TODO: currently doing array of actions to be played to solve delay issue, fix this
    NSArray* actionsToBePlayed = [NSArray arrayWithObjects:
                                  actionStall, // change to this for multiplay
                                  actionRemoveTile,
                                  nil];
    
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