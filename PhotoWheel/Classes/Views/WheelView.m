//
//  PhotoWheelView.m
//  PhotoWheel
//
//  Created by Kirby Turner on 4/20/11.
//  Copyright 2011 White Peak Software Inc. All rights reserved.
//

#import "WheelView.h"
#import "KTOneFingerRotationGestureRecognizer.h"
#import <QuartzCore/QuartzCore.h>


@interface WheelView ()
@property (nonatomic, assign) CGFloat currentAngle;
@property (nonatomic, assign) CGFloat lastAngle;

- (void)commonInit;
- (CGPoint)wheelCenter;
- (void)setStyle:(WheelStyle)style;
- (void)setAngle:(CGFloat)angle;
@end


@implementation WheelView

@synthesize dataSource = dataSource_;
@synthesize style = style_;
@synthesize currentAngle = currentAngle_;
@synthesize lastAngle = lastAngle_;

- (void)dealloc
{
   [super dealloc];
}

- (void)commonInit
{
   [self setCurrentAngle:0.0];
   [self setLastAngle:0.0];
   
   KTOneFingerRotationGestureRecognizer *rotation = [[KTOneFingerRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
   [self addGestureRecognizer:rotation];
   [rotation release];
}

- (id)init
{
   self = [super init];
   if (self) {
      [self commonInit];
   }
   return self;
}

- (id)initWithStyle:(WheelStyle)style
{
   self = [super init];
   if (self) {
      [self setStyle:style];
      [self commonInit];
   }
   return self;
}

- (id)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
   if (self) {
      [self commonInit];
   }
   return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
   self = [super initWithCoder:aDecoder];
   if (self) {
      [self commonInit];
   }
   return self;
}

- (void)layoutSubviews
{
   [self setAngle:[self currentAngle]];
}

- (CGPoint)wheelCenter
{
   CGPoint center = CGPointMake(CGRectGetMidX([self bounds]), CGRectGetMidY([self bounds]));
   return center;
}

- (void)setStyle:(WheelStyle)style
{
   if (style_ != style) {
      style_ = style;
      
      [UIView beginAnimations:@"WheelChangeStyle" context:nil];
      [self setAngle:[self currentAngle]];
      [UIView commitAnimations];
   }
}

- (void)setAngle:(CGFloat)angle
{
   // The follow code is inprised from the carousel example at:
   // http://stackoverflow.com/questions/5243614/3d-carousel-effect-on-the-ipad

   CGPoint center = [self wheelCenter];
   CGFloat radiusX = [self bounds].size.width * 0.35;
   CGFloat radiusY = radiusX;
   if ([self style] == WheelStyleCarousel) {
      radiusY = radiusX * 0.30;
   }
   
   NSInteger nubCount = [[self dataSource] wheelViewNumberOfNubs:self];
   float angleToAdd = 360.0f / nubCount;

   for (NSInteger index = 0; index < nubCount; index++)
   {
      UIView *view = [[self dataSource] wheelView:self nubAtIndex:index];
      if ([view superview] == nil) {
         [self addSubview:view];
      }
      
      float angleInRadians = angle * M_PI / 180.0f;
      
      // get a location based on the angle
      float xPosition = center.x + (radiusX * sinf(angleInRadians));
      float yPosition = center.y + (radiusY * cosf(angleInRadians));
      
      // get a scale too; effectively we have:
      //
      //  0.75f   the minimum scale
      //  0.25f   the amount by which the scale varies over half a circle
      //
      // so this will give scales between 0.75 and 1.0. Adjust to suit!
      float scale = 0.75f + 0.25f * (cosf(angleInRadians) + 1.0);
      
      // apply location and scale
      if ([self style] == WheelStyleCarousel) {
         [view setTransform:CGAffineTransformScale(CGAffineTransformMakeTranslation(xPosition, yPosition), scale, scale)];
         // tweak alpha using the same system as applied for scale, this time
         // with 0.3 the minimum and a semicircle range of 0.5
         [view setAlpha:(0.3f + 0.5f * (cosf(angleInRadians) + 1.0))];
         
      } else {
         [view setTransform:CGAffineTransformMakeTranslation(xPosition, yPosition)];
         [view setAlpha:1.0];
      }
      
      // setting the z position on the layer has the effect of setting the
      // draw order, without having to reorder our list of subviews
      [[view layer] setZPosition:scale];
      
      // work out what the next angle is going to be
      angle += angleToAdd;
   }
}

- (void)reloadData
{
   [self layoutSubviews];
}

//- (void)reloadNubs
//{
//   NSManagedObjectContext *context = [[self photoWheel] managedObjectContext];
//   
//   for (NSInteger index=0; index < [[self nubControllers] count]; index++) {
//      PhotoNubViewController *nubController = [[self nubControllers] objectAtIndex:index];
//      
//      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sortOrder == %i", index];
//      NSSet *nubSet = [[[self photoWheel] nubs] filteredSetUsingPredicate:predicate];
//      if (nubSet && [nubSet count] > 0) {
//         [nubController setNub:[nubSet anyObject]];
//      } else {
//         // Insert a new nub.
//         Photo *newNub = [Photo insertNewInManagedObjectContext:context];
//         [newNub setSortOrder:[NSNumber numberWithInt:index]];
//         [newNub setPhotoWheel:[self photoWheel]];
//         
//         // Save the context.
//         NSError *error = nil;
//         if (![context save:&error])
//         {
//            /*
//             Replace this implementation with code to handle the error appropriately.
//             
//             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
//             */
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//         }
//         
//         [nubController setNub:newNub];
//      }
//   }
//}


#pragma mark - Touch Event Handlers

- (void)rotate:(KTOneFingerRotationGestureRecognizer *)recognizer
{
   CGFloat angleInRadians = -[recognizer rotation];
   [self setLastAngle:[self currentAngle]];
   CGFloat degrees = 180.0 * angleInRadians / M_PI;   // radians to degress
   [self setCurrentAngle:[self currentAngle] + degrees];
   [self setAngle:[self currentAngle]];
}

@end


#pragma mark - WheelViewNub Implementation

@implementation WheelViewNub

@end