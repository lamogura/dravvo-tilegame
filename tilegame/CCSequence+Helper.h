//
//  CCSequence+Helper.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/23/13.
//
// Helper is a Category which extends the CCSequence class

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CCSequence (Helper)

    +(id) actionMutableArray: (NSMutableArray*) actionList_;
@end
