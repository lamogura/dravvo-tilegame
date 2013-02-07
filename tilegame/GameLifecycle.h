//
//  GameLifecycle.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameLifecycle : NSObject

+(void) deleteGameStateSave;
+(void) startWithDirector:(CCDirectorIOS *)director;

@end