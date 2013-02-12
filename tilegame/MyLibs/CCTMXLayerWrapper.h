//
//  CCCacheableTMXLayer.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/12/13.
//
//

#import "CCTMXLayer.h"
#import "EntityNode.h"

typedef enum {
    LayerType_Background,
    LayerType_Foreground,
    LayerType_Destruction,
    LayerType_Meta,
} LayerType;

// used for loading by name from tilemap and for setting layerType
#define kLayerName_Background @"Background"
#define kLayerName_Foreground @"Foreground"
#define kLayerName_Destruction @"Destruction"
#define kLayerName_Meta @"Meta"

@interface CCTMXLayerWrapper : CCNode

@property (nonatomic, strong) CoreGameLayer* gameLayer;
// TODO: change this to use the LayerType enum
@property (nonatomic, assign) NSString* layerType;
@property (nonatomic, strong) CCTMXLayer* tmxLayer;
@property (nonatomic, strong) NSMutableArray* actionsToBePlayedArray;

-(id) initFromTileMap:(CCTMXTiledMap*)tileMap inCoreGameLayer:(CoreGameLayer *)gameLayer layerType:(LayerType)layerType;

-(void) cacheStateForEvent:(DVEventType)event atTileCoordinate:(CGPoint)tileCoordinate;
-(void) playActionsInSequence;// plays all the actions in sequence FOR EACH entity object

-(void) removeTileAt:(CGPoint)tileCoordinate;
-(void) animateRemoveTileAtTileCoordinate:(CGPoint)tileCoordinate afterDelay:(ccTime) delay;

@end