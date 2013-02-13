//
//  ChickenSprite.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/12/13.
//
//

#import "CCSprite.h"
#import "cocos2d.h"
#import "CCSequence+Helper.h"
#import "EntityNode.h"
#import "CoreGameLayer.h"

#define kEntityChickenSpeedPPS 100

@interface ChickenSprite : CCSprite

-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint ownedBy:(EntityNode *)owner;
//-(CCSprite*) removeSpriteAsChildAndReturnIt;

@end
