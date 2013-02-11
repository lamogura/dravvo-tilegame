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

@interface CCCacheableTMXLayer : CCTMXLayer

@property (nonatomic, strong) CCNode* gameLayer;
@property (nonatomic, assign) NSString* layerType;
@property (nonatomic, strong) NSMutableArray* actionsToBePlayed;

-(void)cacheStateForEvent:(DVEventType)event atTileCoordinate:(CGPoint)tileCoordinate;
-(void)removeTileAt:(CGPoint)tileCoordinate;
-(void)animateRemoveTileAtTileCoordinate:(CGPoint)tileCoordinate afterDelay:(ccTime) delay;
-(void)playActionsInSequence;  // plays all the actions in sequence FOR EACH entity object

+(CCCacheableTMXLayer *) layerFromCCTMXLayer:(CCTMXLayer *)layer InCoreGameLayer:(CoreGameLayer *)gameLayer OfType:(LayerType)layerType;

@end
