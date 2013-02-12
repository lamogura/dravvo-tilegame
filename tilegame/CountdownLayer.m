//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Justin Kovalchuk on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CountdownLayer.h"
#import "CoreGameLayer.h"
#import "DVConstants.h"

@implementation CountdownLayer
@synthesize countdownCount = _countdownCount;
@synthesize label = _label;

-(id) initWithCountdownFrom:(int)countFrom AndCallBlockWhenCountdownFinished:(void(^)(id status))block;
{
    if(self=[super initWithColor:ccc4(255,255,255,0)]) {
        self.countdownCount = countFrom;
        _block = block; // save block to call later when cowntdown done
        self.label = [CCLabelTTF labelWithString:[NSString stringWithFormat:kLabelFormat, self.countdownCount] fontName:@"Arial" fontSize:58];
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        self.label.color = ccc3(0,0,0);
        self.label.position = ccp(winSize.width/2, winSize.height/2);
        
        self->_labelAction = [CCScaleBy actionWithDuration:0.9 scale:3.0];
        
        [self addChild:self.label];
        [self.label runAction:self->_labelAction];
        [self schedule:@selector(updateLabel:) interval:1];
    }
    return self;
}

-(void) updateLabel:(ccTime) delta {
    if (--self.countdownCount <= 0) {
        [self unschedule:_cmd];
        [self.parent removeChild:self cleanup:YES];
        _block(nil);
    }
    self.label.scale = 1.0;
    self.label.string = [NSString stringWithFormat:kLabelFormat, self.countdownCount];
    [self.label runAction:self->_labelAction];
}

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [CountdownLayer node]];
	return scene;
}

@end