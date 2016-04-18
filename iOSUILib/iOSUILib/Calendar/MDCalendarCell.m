// The MIT License (MIT)
//
// Copyright (c) 2015 FPT Software
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MDCalendarCell.h"
#import "MDCalendar.h"
#import "UIView+MDExtension.h"
#import "NSDate+MDExtension.h"
#import "UIFontHelper.h"

#define kAnimationDuration 0.15

@interface MDCalendarCell ()

@property(strong, nonatomic) CAShapeLayer *selectedBackgroundLayer;
@property(strong, nonatomic) CAShapeLayer *backgroundLayer;
@property(readonly, nonatomic) BOOL today;
@property(readonly, nonatomic) BOOL weekend;

- (UIColor *)colorForCurrentStateInDictionary:(NSDictionary *)dictionary;

@end

@implementation MDCalendarCell

#pragma mark - Init and life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _separator = [UIView new];
        [_separator setBackgroundColor:[UIColor colorWithRed:166./255. green:166./255. blue:166./255. alpha:0.6]];
        [self.contentView addSubview:_separator];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFontHelper robotoFontWithName:@"CoreSansDS35Regular" size:15];
        //[UIFontHelper robotoFontOfSize:15];
        titleLabel.textColor = [UIColor darkTextColor];
        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;
        self.showPlaceholder = NO;
        
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
        _backgroundLayer.hidden = YES;
        [self.contentView.layer insertSublayer:_backgroundLayer atIndex:0];
        
        _selectedBackgroundLayer = [CAShapeLayer layer];
        _selectedBackgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
        _selectedBackgroundLayer.hidden = YES;
        [self.contentView.layer insertSublayer:_selectedBackgroundLayer atIndex:0];
        
    }
    NSLog(@"CELL H:%f\nW:%f",frame.size.height,frame.size.width);
    return self;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [_separator setFrame:CGRectMake(-2, 0, self.bounds.size.width+5, 1)];
    CGFloat titleHeight = _titleLabel.font.lineHeight;
    //self.bounds.size.height * 4.0 / 6.0;
    CGFloat diameter = MIN(titleHeight, self.bounds.size.width);
    diameter = diameter * 1.6;
    diameter = MIN(diameter,
                   self.titleLabel.font.lineHeight * 2); // maximun selection rect
    
    _backgroundLayer.frame = CGRectMake((self.bounds.size.width - diameter) / 2,
                                        2, diameter, diameter);
//    CGRectMake((self.bounds.size.width - diameter) / 2,
//               (titleHeight - diameter) / 2, diameter, diameter);
    
    _selectedBackgroundLayer.frame = CGRectMake((self.bounds.size.width - (diameter/2)) / 2,
                                                2+ diameter + 4,
                                                diameter/2, diameter/2);
   
//    CGRectMake((self.bounds.size.width - (diameter/2)) / 2,
//                                                (titleHeight - diameter) / 2 + diameter + 4,
//                                                diameter/2, diameter/2);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [CATransaction setDisableActions:YES];
}

#pragma mark - Setters

- (void)setDate:(NSDate *)date {
    if (![_date isEqualToDate:date]) {
        _date = date;
    }
    [self configureCell];
}

- (void)showAnimation {
    _backgroundLayer.hidden = NO;
    _selectedBackgroundLayer.hidden = !(self.isToday && !self.isPlaceholder);
    
    _backgroundLayer.path =
    [UIBezierPath bezierPathWithOvalInRect:_backgroundLayer.bounds].CGPath;
    _selectedBackgroundLayer.path =  [UIBezierPath bezierPathWithOvalInRect:_selectedBackgroundLayer.bounds].CGPath;
    
    _backgroundLayer.fillColor =
    [self colorForCurrentStateInDictionary:_backgroundColors].CGColor;
    _selectedBackgroundLayer.fillColor = [UIColor colorWithRed:169./255. green:238./255. blue:253./255. alpha:1.].CGColor;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    CABasicAnimation *zoomOut =
    [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomOut.fromValue = @0.3;
    zoomOut.toValue = @1.2;
    zoomOut.duration = kAnimationDuration / 4 * 3;
    CABasicAnimation *zoomIn =
    [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomIn.fromValue = @1.2;
    zoomIn.toValue = @1.0;
    zoomIn.beginTime = kAnimationDuration / 4 * 3;
    zoomIn.duration = kAnimationDuration / 4;
    group.duration = kAnimationDuration;
    group.animations = @[ zoomOut, zoomIn ];
    [_backgroundLayer addAnimation:group forKey:@"bounce"];
    [_selectedBackgroundLayer addAnimation:group forKey:@"bounce"];
    [self configureCell];
}

- (void)hideAnimation {
    _backgroundLayer.hidden = YES;
    [self configureCell];
}

#pragma mark - Private

- (void)configureCell {
    _titleLabel.text = [NSString stringWithFormat:@"%@", @(_date.mdDay)];
    _titleLabel.textColor = [self colorForCurrentStateInDictionary:_titleColors];
    _titleLabel.hidden = self.isPlaceholder && !self.showPlaceholder;
    _backgroundLayer.fillColor =
    [self colorForCurrentStateInDictionary:_backgroundColors].CGColor;
    _selectedBackgroundLayer.fillColor = [UIColor colorWithRed:169./255. green:238./255. blue:253./255. alpha:1.].CGColor;
    
    _titleLabel.frame = CGRectMake(0, (2 + _backgroundLayer.frame.size.height/2 - (_titleLabel.font.lineHeight/2)), self.mdWidth, _titleLabel.font.lineHeight);//CGRectMake(0, 0, self.mdWidth, _titleLabel.font.lineHeight);
    
    
                                  // floor(self.contentView.mdHeight * 4.0 / 6.0));
    
    _backgroundLayer.hidden = !self.selected && !self.isToday;
    _backgroundLayer.path =
    _cellStyle == MDCalendarCellStyleCircle
    ? [UIBezierPath bezierPathWithOvalInRect:_backgroundLayer.bounds]
    .CGPath
    : [UIBezierPath bezierPathWithRect:_backgroundLayer.bounds].CGPath;
    
    _selectedBackgroundLayer.hidden = !(self.isToday && !self.isPlaceholder);
    _selectedBackgroundLayer.path =  [UIBezierPath bezierPathWithOvalInRect:_selectedBackgroundLayer.bounds].CGPath;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self configureCell];
}

- (BOOL)isPlaceholder {
    return ![_date mdIsEqualToDateForMonth:_month];
}

- (BOOL)isToday {
    return [_date mdIsEqualToDateForDay:_currentDate];
}

- (BOOL)isWeekend {
    return self.date.mdWeekday == 1 || self.date.mdWeekday == 7;
}

- (UIColor *)colorForCurrentStateInDictionary:(NSDictionary <NSNumber*, UIColor*>*)dictionary {
    if (self.isSelected) {
        return dictionary[@(MDCalendarCellStateSelected)];
    }
    if (self.isToday) {
        return dictionary[@(MDCalendarCellStateToday)];
    }
    if (self.isPlaceholder) {
        return dictionary[@(MDCalendarCellStatePlaceholder)];
    }
    if (self.isWeekend &&
        [[dictionary allKeys] containsObject:@(MDCalendarCellStateWeekend)]) {
        return dictionary[@(MDCalendarCellStateWeekend)];
    }
    return dictionary[@(MDCalendarCellStateNormal)];
}

@end
