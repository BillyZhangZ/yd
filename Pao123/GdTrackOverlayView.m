//
//  GdTrackOverlayView.m
//  Pao123
//
//  Created by Zhenyong Chen on 7/3/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "GdTrackOverlayView.h"

@interface Track : NSObject
@property (nonatomic) CGPoint *pointList;
@property (nonatomic) NSUInteger count; // points accumulated in pointList
@property (nonatomic) NSUInteger capacity; // capacity of pointList
@property (nonatomic) NSInteger pointsToPlay; // how many points in pointList to draw
@property (nonatomic) CLLocation *playToLocation; // the last location to play to
@end

@implementation Track

- (instancetype) init
{
    self = [super init];
    if(self != nil) {
        _pointList = nil;
        _count = 0;
        _pointsToPlay = 0;
        _capacity = 0;
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"Delete a track");
    if(_pointList != NULL)
        free(_pointList);
}
@end

@interface GdTrackOverlayView ()
{
    NSMutableArray *_tracks;
    SessionLocationPath _lastTranslatePosition;
    GLuint _endImageTexture;
}

@end

@implementation GdTrackOverlayView

- (id)initWithTrackOverlay:(GdTrackOverlay *)overlay;
{
    self = [super initWithOverlay:overlay];
    if (self)
    {
        _tracks = [[NSMutableArray alloc] init];
        _lastTranslatePosition.session = _lastTranslatePosition.locationInSession = -1;
        _endImageTexture = 0;
    }

    return self;
}

- (void)dealloc
{
    NSLog(@"GdTrackOverlayView: dealloc");
}

- (GdTrackOverlay *)trackOverlay
{
    return (GdTrackOverlay *)self.overlay;
}

- (void)referenceDidChange
{
    GdTrackOverlay *overlay = self.trackOverlay;
    if(overlay != nil) {
        _lastTranslatePosition.session = _lastTranslatePosition.locationInSession = -1;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

/* update Track.pointList
 * if 'from' is -1, then start from 0; if 'to' is -1, then calculate all points
 */
- (void) recalcPoints:(NSArray *)coordsArray from:(SessionLocationPath)from to:(SessionLocationPath) to
{
    if(coordsArray == nil)
        return;

    NSInteger firstSession = 0;
    if(from.session >= 0)
        firstSession = from.session;
    NSInteger endSession = coordsArray.count-1;
    if(to.session >= 0 && to.session < endSession)
        endSession = to.session;
    
    for(NSInteger si = firstSession; si <= endSession; si++) {
        NSArray *coords = [coordsArray objectAtIndex:si];
        NSInteger pointCount = coords.count;
        if(pointCount == 0) // empty
            continue;
        
        NSInteger firstLocation;
        if(si == firstSession && from.locationInSession > 0)
            firstLocation = from.locationInSession;
        else
            firstLocation = 0;
        
        NSInteger endLocation;
        if(si == endSession && to.locationInSession > 0)
            endLocation = to.locationInSession;
        else
            endLocation = pointCount - 1;
        

        // tracks
        if(si < _tracks.count) {
            // track is already created; update it
            Track *dst = [_tracks objectAtIndex:si];
            if(dst.capacity < endLocation + 1) {
                dst.capacity = 2 * (endLocation + 1);
                dst.pointList = (CGPoint *)realloc(dst.pointList, sizeof(CGPoint) * dst.capacity);
            }
            [self translate:coords to:dst.pointList start:firstLocation end:endLocation track:dst];
            dst.count = endLocation + 1;
        }
        else {
            NSAssert(si == _tracks.count, @"track is missing");
            // create a new track
            Track *dst = [[Track alloc] init];
            dst.capacity = endLocation + 1;
            if(dst.capacity < 1900)
                dst.capacity = 1900;
            dst.pointList = (CGPoint *)malloc(sizeof(CGPoint) * dst.capacity);
            [self translate:coords to:dst.pointList start:firstLocation end:endLocation track:dst];
            dst.count = endLocation + 1;
            [_tracks addObject:dst];
        }
    }
}

- (void) translate:(NSArray *)coords to:(CGPoint *)pointList start:(NSInteger)firstLocation end:(NSInteger)endLocation track:(Track *)track
{
    for(NSInteger i=firstLocation; i<=endLocation; i++)
    {
        CLLocation *loc = [coords objectAtIndex:i];
        pointList[i] = [self glPointForMapPoint:MAMapPointForCoordinate(loc.coordinate)];
    }
    
    // determine points to play
    if(self.trackOverlay.playToTime == nil) {
        track.pointsToPlay = track.count;
        track.playToLocation = [coords lastObject];
    }
    else {
        for(NSInteger i=track.pointsToPlay; i<=endLocation; i++) {
            CLLocation *loc = [coords objectAtIndex:i];
            if([loc.timestamp compare:self.trackOverlay.playToTime] != NSOrderedDescending) {
                track.pointsToPlay = i;
                track.playToLocation = loc;
            }
            else
                break;
        }
    }
}

- (CLLocation *) currentEndLocation
{
    for (NSInteger i=_tracks.count-1; i>=0 ; i--) {
        Track *track = [_tracks objectAtIndex:i];
        if(track != nil && track.playToLocation != nil)
            return track.playToLocation;
    }

    return nil;
}

- (void) glRender
{
    GdTrackOverlay *overlay = self.trackOverlay;
    if(overlay == nil)
        return;

    [overlay updateGeometry];
    
    SessionLocationPath to = overlay.lastSessionLocation;
    [self recalcPoints:overlay.coordsArray from:_lastTranslatePosition to:to];
    _lastTranslatePosition = to;
    
    overlay.lastLocation = [self currentEndLocation];

    // draw tracks
    for(NSUInteger i=0; i<_tracks.count; i++) {
        Track *track = [_tracks objectAtIndex:i];
        [self drawLineWithPoints:track.pointList pointCount:track.pointsToPlay];
    }
}

- (void) drawLineWithPoints:(CGPoint *)points pointCount:(NSUInteger)pointCount
{
    if (points == NULL || pointCount < 2)
    {
        return;
    }

    /* Drawing line. */
    [self renderLinesWithPoints:points pointCount:pointCount strokeColor:self.strokeColor lineWidth:[self glWidthForWindowWidth:self.lineWidth] looped:NO LineJoinType:self.lineJoinType LineCapType:self.lineCapType lineDash:self.lineDash];
    
    /* Draw an image */
    if(self.trackOverlay.endPoingImage != nil)
    {
        if(_endImageTexture == 0) {
            _endImageTexture = [self loadStrokeTextureImage:self.trackOverlay.endPoingImage];
        }
        
        if(_endImageTexture != 0) {
            CGPoint cgPoints[4];
            CLLocation *loc = self.trackOverlay.lastLocation;
            cgPoints[0] = [self glPointForMapPoint:MAMapPointForCoordinate(loc.coordinate)];
            GLfloat delta = [self glWidthForWindowWidth:32];
            cgPoints[1].x = cgPoints[0].x - delta;
            cgPoints[1].y = cgPoints[0].y;
            cgPoints[2].x = cgPoints[1].x;
            cgPoints[2].y = cgPoints[1].y - delta;
            cgPoints[3].x = cgPoints[0].x;
            cgPoints[3].y = cgPoints[2].y;

            [self renderIconWithTextureID:_endImageTexture points:cgPoints];
        }
    }
}

@end
