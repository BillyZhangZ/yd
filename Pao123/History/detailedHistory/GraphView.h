//
//  GraphView.h
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface GraphView : UIView {
    
    NSMutableArray *_pointArray;
    
    float dx; 
    float dy;
    
    int spacing;
    
    BOOL fillGraph;
        
    UILabel *_max;
    UILabel *_zero;
    UILabel *_min;
    
    int setZero;
    
    UIColor *_strokeColor;
    UIColor *_fillColor;
    
    UIColor *_zeroLineStrokeColor;
    
    int lineWidth;
    
    int granularity;
    
}

// add point to the array dynamically
-(void)setPoint:(float)point;

// reset graph to all 0.0 values
-(void)resetGraph;

// set an array of alues to be displayed in a the graph
-(void)setArray:(NSArray*)array ;

// set the spacing from the max value in graph array to top of view. default = 10.
-(void)setSpacing:(int)space;

// set the view to fill below graph. default = YES
-(void)setFill:(BOOL)fill;

// set the color of the graph line. default = [UIColor redColor].
-(void)setStrokeColor:(UIColor*)color;

// set the color of the zero line. default = [UIColor greenColor].
-(void)setZeroLineStrokeColor:(UIColor*)color;

// set the filled space below graph. default = [UIColor orangeColor].
-(void)setFillColor:(UIColor*)color;

// set the color of the graph line. default = 2.
-(void)setLineWidth:(int)width;

// set up the number of values diplayes in the graph along the x-axis
-(void)setNumberOfPointsInGraph:(int)numberOfPoints;

// set curved graph lines. default = YES;
-(void)setCurvedLines:(BOOL)curved;

@end
