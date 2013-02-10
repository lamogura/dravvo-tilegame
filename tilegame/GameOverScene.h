//
//  GameOverScene.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface GameOverLayer : CCLayerColor

+(CCScene *) sceneWithLabelText:(NSString *)pLabelText;

-(id) initWithLabelText:(NSString *)pLabelText;

@end
