//
//  gameConstants.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/21/13.
//
//

// List of different enumerated AI behaviors, each defined uniquely within entity's method definitions
#define kBehavior_default 0    // entity will take its default actions
#define kBehavior_idle 1    // entity will take no actions
#define kBehavior_attackOpponent 2  // entity will attack opponent
#define kBehavior_attackPlayer 3    // entity will attack player
#define kBehavior_random 4  // entity will take random actions

#define kNumMelons 5
#define kInitShurikens 10
#define kInitMissiles 10
#define kMaxMelons 5
#define kTimeStepSeconds 1  // time step for sampling rate and oponnent turn re-play animation rate