//
//  CoreGameHud.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"

// Heads Up Display HUD label / stats layer class declaration (put in separate file in future)
@interface CoreGameHudLayer : CCLayer {
    CCLabelTTF* _labelMelonsCount;
    CCLabelTTF* _labelKillsCount;
    CCLabelTTF* _labelShurikensCount;
    CCLabelTTF* _labelMissilesCount;
    CCLabelTTF* _labelTimer;
}
@property (nonatomic, unsafe_unretained) HelloWorldLayer* gameLayer;

-(void) projectileButtonTapped:(id) sender;
-(void) numCollectedChanged:(int) numCollected;
-(void) numKillsChanged:(int) numKills;
-(void) numShurikensChanged:(int) numShurikens;
-(void) numMissilesChanged:(int) numMissiles;
-(void) timerChanged:(int) newTime;

@end