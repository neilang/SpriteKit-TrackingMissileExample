//
//  NAMyScene.m
//  TrackingMissileExample
//
//  Created by Neil Ang on 1/02/2014.
//  Copyright (c) 2014 Neil Ang. All rights reserved.
//

#import "NAMyScene.h"

// Don't set this too low or it may never hit its target
#define NA_MISSILE_THRUST 300.0f
// Don't set this too high or the missile may never reach it
#define NA_ENEMY_SPEED    20.0f

#define NA_ENEMY_LABEL   @"enemy"
#define NA_MISSILE_LABEL @"missile"
#define NA_TARGET_KEY    @"target"

typedef NS_OPTIONS(NSInteger, NACategory)
{
    NACategoryMissile = 1 << 0,
    NACategoryEnemy   = 1 << 1,
};


@implementation NAMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        [self setupScene];
    }
    return self;
}

-(void)setupScene {
    
    // World physics
    self.physicsWorld.gravity         = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;

    // The background
    self.backgroundColor = [SKColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    SKEmitterNode *stars = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"stars" ofType:@"sks"]];
    stars.position       = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    [self addChild:stars];

    // Our ship
    self.ship           = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    self.ship.scale     = 0.5f;
    self.ship.position  = CGPointMake(CGRectGetWidth(self.ship.frame)/2.0f, CGRectGetHeight(self.ship.frame)/2.0f);
    self.ship.zRotation = (315 * M_PI) / 180;
 
    [self addChild:self.ship];
    
    [self setupShipMovement];

}

-(void)setupShipMovement{
    CGFloat speed    = 0.8f;
    SKAction *step1  = [SKAction moveByX:5.0f   y:15.0f  duration:speed];
    SKAction *step2  = [SKAction moveByX:15.0f  y:5.0f duration:speed];
    SKAction *step3  = [SKAction moveByX:-5.0f  y:-5.0f  duration:speed];
    SKAction *step4  = [SKAction moveByX:-15.0f y:-15.0f duration:speed];

    SKAction *movement = [SKAction sequence:@[step1, step2, step3, step4]];
    [self.ship runAction:[SKAction repeatActionForever:movement]];
}

-(SKNode *)newEnemyNode {
    
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(50, 50)];
    enemy.physicsBody   = [SKPhysicsBody bodyWithRectangleOfSize:enemy.size];
    enemy.name          = NA_ENEMY_LABEL;

    // Setup physics interaction
    enemy.physicsBody.categoryBitMask    = NACategoryEnemy;
    enemy.physicsBody.collisionBitMask   = NACategoryEnemy;
    enemy.physicsBody.contactTestBitMask = NACategoryMissile;

    // Make them spin a little
    enemy.physicsBody.angularVelocity    = 3;
    
    return enemy;
}

-(SKNode *)newMissileNode {
    SKEmitterNode *missile = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"missile" ofType:@"sks"]];
    missile.targetNode     = self;
    missile.name           = NA_MISSILE_LABEL;
    missile.physicsBody    = [SKPhysicsBody bodyWithCircleOfRadius:1.0f];
    
    // Setup physics interaction
    missile.physicsBody.categoryBitMask    = NACategoryMissile;
    missile.physicsBody.collisionBitMask   = 0;
    missile.physicsBody.contactTestBitMask = NACategoryEnemy;
    
    return missile;
}

-(CGPoint)shipNose {
    // Calculate ships nose position after the zRotation is applied.
    // This is done dynamically so that move actions can be applied to the ship.
    
    CGPoint origin  = self.ship.position;
    CGPoint nose    = CGPointMake(origin.x, (self.ship.size.height)/2.0f + origin.y);
    CGFloat theta   = self.ship.zRotation;
    
    CGFloat cosTheta = cos(theta);
    CGFloat sinTheta = sin(theta);

    nose.x -= origin.x;
    nose.y -= origin.y;

    CGFloat rotatedX = (nose.x * cosTheta) - (nose.y * sinTheta);
    CGFloat rotatedY = (nose.x * sinTheta) + (nose.y * cosTheta);
    
    return CGPointMake(rotatedX+origin.x, rotatedY+origin.y);
}

-(void)mouseDown:(NSEvent *)theEvent {
    
    // Spawn an enemy at mouse point
    SKNode *enemy  = [self newEnemyNode];
    enemy.position = [theEvent locationInNode:self];
    
    [self addChild:enemy];
    
    // Give the enemy a push
    [enemy.physicsBody applyImpulse:CGVectorMake(-NA_ENEMY_SPEED, -NA_ENEMY_SPEED)];
    
    // At the same time we want to spawn a missile to attack our enemy.
    SKNode *missile  = [self newMissileNode];
    missile.position = [self shipNose];
    
    // Each missile is targeted to a particular enemy, so we need to store a reference to it
    missile.userData = [NSMutableDictionary dictionaryWithObject:enemy forKey:NA_TARGET_KEY];
    
    [self addChild:missile];
    
}

-(void)updateMissileVelocity:(SKNode *)missile {
    SKNode *target = [missile.userData objectForKey:NA_TARGET_KEY];
    
    assert(target);
    
    float x = missile.position.x - target.position.x;
    float y = target.position.y  - missile.position.y;
    CGFloat direction = atan2f(x, y) + M_PI_2;
    
    CGFloat velocityX = NA_MISSILE_THRUST * cos(direction);
    CGFloat velocityY = NA_MISSILE_THRUST * sin(direction);

    CGVector newVelocity = CGVectorMake(velocityX, velocityY);
    
#if DEBUG
    if (newVelocity.dx < target.physicsBody.velocity.dx && newVelocity.dy < target.physicsBody.velocity.dy) {
        NSLog(@"WARNING: target moving faster than missile");
    }
#endif
    
    missile.physicsBody.velocity = newVelocity;
}

-(void)update:(CFTimeInterval)currentTime {
    [self enumerateChildNodesWithName:NA_MISSILE_LABEL usingBlock:^(SKNode *node, BOOL *stop){
        [self updateMissileVelocity:node];
    }];
}

- (SKEmitterNode*) newExplosionNode: (CFTimeInterval) explosionDuration {
    SKEmitterNode *explosion     = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"explosion" ofType:@"sks"]];
    explosion.targetNode         = self;
    explosion.numParticlesToEmit = explosionDuration * explosion.particleBirthRate;
    CFTimeInterval totalTime     = explosionDuration + explosion.particleLifetime+explosion.particleLifetimeRange/2;
    [explosion runAction:[SKAction sequence:@[[SKAction waitForDuration:totalTime], [SKAction removeFromParent]]]];
    return explosion;
}

-(void)explodeAtPoint:(CGPoint)point {
    SKEmitterNode *explosion = [self newExplosionNode:0.1f];
    explosion.position       = point;
    [self addChild:explosion];
}

-(void)handleMissile:(SKNode *)missile contactWith:(SKNode *)contactNode {
    
    // Check if it is an enemy node we've hit.
    if (contactNode.physicsBody.categoryBitMask != NACategoryEnemy) {
        return;
    }
    
    SKNode *missileTarget = [missile.userData objectForKey:NA_TARGET_KEY];
    
    assert(missileTarget);
    
    // Check we haven't hit the wrong enemy
    if (missileTarget != contactNode) {
        return;
    }
    
    // At this point we can assume we've hit our target.
    
    [self explodeAtPoint:contactNode.position];
    
    // Cleanup
    [contactNode removeFromParent];
    [missile removeFromParent];

    NSLog(@"TARGET DESTROYED!");

}

#pragma mark - SKPhysicsContactDelegate

-(void)didBeginContact:(SKPhysicsContact *)contact {

    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;

    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody  = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody  = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == NACategoryMissile){
        [self handleMissile:firstBody.node contactWith:secondBody.node];
    }

}


@end
