//
//  GraphView.h
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor yellowColor];
        
        fillGraph = YES;
        
        spacing = 10;
        
        _strokeColor = [UIColor redColor];
        
        _fillColor = [UIColor orangeColor];
        
        _zeroLineStrokeColor = [UIColor greenColor];
        
        lineWidth = 2;
        
        _max = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, 25, 16)];
        [_max setAdjustsFontSizeToFitWidth:YES];
        [_max setBackgroundColor:[UIColor clearColor]];
        [_max setTextColor:[UIColor blackColor]];
        [_max setText:@"10"];
        [self addSubview:_max];
        
        _zero = [[UILabel alloc] initWithFrame:CGRectMake(2, CGRectGetMidY(self.frame) - 7.5, 25, 16)];
        [_zero setAdjustsFontSizeToFitWidth:YES];
        [_zero setBackgroundColor:[UIColor clearColor]];
        [_zero setTextColor:[UIColor blackColor]];
        [self addSubview:_zero];
        
        _min = [[UILabel alloc] initWithFrame:CGRectMake(2, CGRectGetHeight(self.frame)-15, 25, 16)];
        [_min setAdjustsFontSizeToFitWidth:YES];
        [_min setBackgroundColor:[UIColor clearColor]];
        [_min setTextColor:[UIColor blackColor]];
        [_min setText:@"0"];
        [self addSubview:_min];
        
        dx = 50; // number of points shown in graph
        dy = 100; // default value for dy
        
        _pointArray = [[NSMutableArray alloc]init]; //stores the energy values
        for (int i = 0; i < dx; i++) {
            [_pointArray addObject:@0.0f];
        }
        
    }
    
    return self;
}

-(void)setPoint:(float)point {
    
    [_pointArray insertObject:@(point) atIndex:0];
    [_pointArray removeObjectAtIndex:[_pointArray count] - 1];
    
    [self setNeedsDisplay];
}

-(void)resetGraph {
        
    _pointArray = [[NSMutableArray alloc]init]; //stores the energy values
    for (int i = 0; i < dx; i++) {
        [_pointArray addObject:@0.0f];
    }
    
    [self setNeedsDisplay];
    
}

-(void)setArray:(NSArray*)array {
    _pointArray = [[NSMutableArray alloc]initWithArray:array];
    
    dx = [_pointArray count];
    [self setNeedsDisplay];
}

-(void)setSpacing:(int)space {
    
    spacing = space;
    
    [self setNeedsDisplay];
}

-(void)setFill:(BOOL)fill {
    
    fillGraph = fill;
    
    [self setNeedsDisplay];
}

-(void)setStrokeColor:(UIColor*)color {
    
    _strokeColor = color;
    
    [self setNeedsDisplay];
}

-(void)setZeroLineStrokeColor:(UIColor*)color {
    
    _zeroLineStrokeColor = color;
    
    [self setNeedsDisplay];
}

-(void)setFillColor:(UIColor*)color {
    
    _fillColor = color;
    
    [self setNeedsDisplay];
}

-(void)setLineWidth:(int)width {
    
    lineWidth = width;
    
    [self setNeedsDisplay];
}

-(void)setNumberOfPointsInGraph:(int)numberOfPoints {
    
    dx = numberOfPoints;
    
    if ([_pointArray count] < dx) {
        
        int dCount = dx - [_pointArray count];
        
        for (int i = 0; i < dCount; i++) {
            [_pointArray addObject:@(0.0f)];
        }
        
    }
    
    if ([_pointArray count] > dx) {
        
        int dCount = [_pointArray count] - dx;
        
        for (int i = 0; i < dCount; i++) {
            [_pointArray removeLastObject];
        }
        
    }
    
    [self setNeedsDisplay];
    
}

-(void)setCurvedLines:(BOOL)curved {
    
    //the granularity value sets "curviness" of the graph depending on amount wanted and precission of the graph
    
    if (curved == YES) {
        granularity = 20;
    }else{
        granularity = 0;
    }
}

// here the graph is actually being drawn
- (void)drawRect:(CGRect)rect {
    
    [self calculateHeight];
    
    NSArray *lineColors = [[NSArray alloc] initWithObjects:[UIColor grayColor],[UIColor blueColor],[UIColor cyanColor],[UIColor greenColor],[UIColor yellowColor],[UIColor redColor],[UIColor blackColor],[UIColor blackColor], nil];
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    NSMutableArray *points = [[self arrayOfPoints] mutableCopy];
    if (points == nil || [points count] == 0) {
        return;
    }
    // Add control points to make the math make sense
    for (NSUInteger index = 1; index < points.count-1; index++)
    {
        UIBezierPath *line = [UIBezierPath bezierPath];
        line.lineCapStyle = kCGLineCapRound;
        line.lineJoinStyle = kCGLineJoinRound;
        line.flatness = 0.5;
        line.lineWidth = lineWidth;
        
        CGPoint startPoint = [(NSValue *)points[index - 1] CGPointValue];
        CGPoint endPoint = [(NSValue *)points[index] CGPointValue];
        [line moveToPoint:startPoint];
        [line addLineToPoint:endPoint];
        
        int heartRateLevel = (((int)[_pointArray[index] floatValue]) - 110)/10;
        if (heartRateLevel < 0) {
            heartRateLevel = 0;
        }
        if (heartRateLevel > 5) {
            heartRateLevel = 5;
        }
        //NSLog(@"color level %d", heartRateLevel);
        _strokeColor = [lineColors objectAtIndex:heartRateLevel];
        [_strokeColor setStroke];
        [lines addObject:line];
        [line stroke];
    }
}

- (NSArray*)arrayOfPoints {
    
    NSMutableArray *points = [NSMutableArray array];
    
    int viewWidth = CGRectGetWidth(self.frame);
    int viewHeight = CGRectGetHeight(self.frame);
    
    for (int i = 0; i < [_pointArray count]; i++) {
        
        float point1x = (viewWidth / dx) * i; // start graph x on the left hand side
        float point1y = (viewHeight - (viewHeight / dy) * [_pointArray[i] floatValue]) / setZero; //start graph y on the bottom
        
        float point2x = (viewWidth / dx) * i - (viewWidth / dx);
        float point2y = point1y;
        
        if (i != [_pointArray count]-1) {
            point2y = (viewHeight - (viewHeight / dy) * [_pointArray[i+1] floatValue]) / setZero;
        }

        CGPoint p;
        
        if (i == 0) {
            p = CGPointMake(point1x, point1y);
        }else{
            p = CGPointMake(point2x, point2y);
        }
        [points addObject:[NSValue valueWithCGPoint:p]];
    }
        
    return points;
        
}

// this is where the dynamic height of the graph is calculated
-(void)calculateHeight {
   
    int minValue = (int)[[_pointArray valueForKeyPath:@"@min.self"] integerValue];
    int maxValue = (int)[[_pointArray valueForKeyPath:@"@max.self"] integerValue];
    
    dy = maxValue /*+ abs(minValue) */+ spacing;
    
    // set maxValue and round the float
    [_max setText:[NSString stringWithFormat:@"%i", (int)(dy + 0.0) ]];
    
    
    // set graphView for values below 0
    if (minValue < 0) {
        setZero = 2;
        [_zero setText:@"0"];
        [_min setText:[NSString stringWithFormat:@"-%i", (int)(dy + 0.0) ]];
    }else{
        setZero = 1;
        [_zero setText:@""];
        [_min setText:[NSString stringWithFormat:@"0"]];
    }
}

@end
