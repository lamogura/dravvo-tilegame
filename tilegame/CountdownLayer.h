//
//  NewGameScene.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "DVAPIWrapper.h"

#define kLabelFormat @"%d"

@interface CountdownLayer : CCLayerColor {
    id _labelAction;
    void (^_block)(id);
}

@property (nonatomic, assign) int countdownCount;
@property (nonatomic, strong) CCLabelTTF* label;

-(id) initWithCountdownFrom:(int)countFrom AndCallBlockWhenCountdownFinished:(void(^)(id status))block;
-(void) updateLabel:(ccTime) delta;
+(CCScene *) scene;

@end