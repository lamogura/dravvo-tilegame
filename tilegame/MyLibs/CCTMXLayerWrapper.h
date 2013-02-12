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

#define kLayerTypeBackground @"background"
#define kLayerTypeForeground @"foreground"
#define kLayerTypeDestruction @"destruction"
#define kLayerTypeMeta @"meta"

@interface CCTMXLayerWrapper : CCNode

@property (nonatomic, strong) CoreGameLayer* gameLayer;
@property (nonatomic, assign) NSString* layerType;
@property (nonatomic, strong) CCTMXLayer* tmxLayer;
//@property (nonatomic, strong) NSMutableArray* actionsToBePlayed;
@property (nonatomic, strong) NSMutableArray* actionsToBePlayedArray;

-(id) initWithlayerFromTileMap:(CCTMXTiledMap*)tileMap InCoreGameLayer:(CoreGameLayer *)gameLayer OfType:(LayerType)layerType;
-(void)cacheStateForEvent:(DVEventType)event atTileCoordinate:(CGPoint)tileCoordinate;
-(void)removeTileAt:(CGPoint)tileCoordinate;
-(void)animateRemoveTileAtTileCoordinate:(CGPoint)tileCoordinate afterDelay:(ccTime) delay;
-(void)playActionsInSequence;// plays all the actions in sequence FOR EACH entity object

@end