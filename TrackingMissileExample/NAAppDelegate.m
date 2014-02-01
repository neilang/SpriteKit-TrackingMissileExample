//
//  NAAppDelegate.m
//  TrackingMissileExample
//
//  Created by Neil Ang on 1/02/2014.
//  Copyright (c) 2014 Neil Ang. All rights reserved.
//

#import "NAAppDelegate.h"
#import "NAMyScene.h"

@implementation NAAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /* Pick a size for the scene */
    SKScene *scene = [NAMyScene sceneWithSize:CGSizeMake(1024, 768)];

    /* Set the scale mode to scale to fit the window */
    scene.scaleMode = SKSceneScaleModeAspectFit;

    [self.skView presentScene:scene];

    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
