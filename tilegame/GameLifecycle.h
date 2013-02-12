//
//  GameLifecycle.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "DVAPIWrapper.h"

@interface GameLifecycle : NSObject

+(void) deleteSaveGame:(NSString *)saveGamePath;
+(GameLifecycle *) startWithOptions:(NSDictionary *)launchOptions;

-(void) roundHasFinished:(NSNotification *) notification;
-(void) processNotification:(NSDictionary *) notificationInfo;

-(void) playNewGame;
-(void) playNextRoundInGameWithID:(NSString *)gameID;

@end