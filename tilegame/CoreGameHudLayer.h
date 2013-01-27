//
//  CoreGameHud.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CoreGameLayer.h"

#define kHUDStringFormat_Melons    @"melons: %d"
#define kHUDStringFormat_Kills     @"kills: %d"
#define kHUDStringFormat_Timer     @"time: %d"
#define kHUDStringFormat_Missles   @"M: %d"
#define kHUDStringFormat_Shurikens @"S: %d"

// Heads Up Display HUD label / stats layer class declaration (put in separate file in future)
@interface CoreGameHudLayer : CCLayer {
    CCLabelTTF* _labelMelons;
    CCLabelTTF* _labelKills;
    CCLabelTTF* _labelShurikens;
    CCLabelTTF* _labelMissiles;
    CCLabelTTF* _labelTimer;
}

-(id) initWithCoreGameLayer:(CoreGameLayer *)layer;

@end