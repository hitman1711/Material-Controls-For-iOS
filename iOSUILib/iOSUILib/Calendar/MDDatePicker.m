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

#import <Foundation/Foundation.h>
#import "MDDatePicker.h"
#import "UIView+MDExtension.h"
#import "MDCalendarDateHeader.h"

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) // iPhone and       iPod touch style UI

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)


@interface MDDatePicker ()

@property(nonatomic) NSNumber *headerHeight;
@property(nonatomic) MDCalendarDateHeader *header;
@property(nonatomic) MDCalendar *calendar;
@end

@implementation MDDatePicker

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupContent];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self setupContent];
  }
  return self;
}

- (void)setupContent {
    CGFloat tableHeight = 470;
    NSNumber *freeSpace = @([[UIScreen mainScreen] bounds].size.height - tableHeight);
    _headerHeight = @0;//freeSpace>0 ? freeSpace : @1;
    //IS_IPHONE_6 ? @190. : IS_IPHONE_5 ? @90. : @20.;
  _header = [[MDCalendarDateHeader alloc]
      initWithFrame:CGRectMake(0, 0, self.mdWidth, _headerHeight.floatValue)];
  [self addSubview:_header];
    
    NSLog(@"CHEIGHT:%f",self.mdHeight - _headerHeight.floatValue);
  MDCalendar *calendar = [[MDCalendar alloc]
      initWithFrame:CGRectMake(0, _headerHeight.floatValue, self.mdWidth,
                               self.mdHeight - _headerHeight.floatValue)];
  calendar.dateHeader = _header;
  [self addSubview:calendar];
  self.calendar = calendar;

  self.calendar.theme = MDCalendarThemeCustom;//MDCalendarThemeLight;

  [self setBackgroundColor:self.calendar.backgroundColor];
}

- (void)layoutSubviews {
  UIInterfaceOrientation orientation =
      [[UIApplication sharedApplication] statusBarOrientation];
  switch (orientation) {
  case UIInterfaceOrientationPortrait:
  case UIInterfaceOrientationPortraitUpsideDown: {
    // load the portrait view
    _header.frame = CGRectMake(0, 0, self.mdWidth, _headerHeight.floatValue);
    _calendar.frame = CGRectMake(0, _headerHeight.floatValue, self.mdWidth,
                                 self.mdHeight - _headerHeight.floatValue);
  }

  break;
  case UIInterfaceOrientationLandscapeLeft:
  case UIInterfaceOrientationLandscapeRight: {
    // load the landscape view
    _header.frame = CGRectMake(0, 0, self.mdWidth / 2, self.mdHeight);
    _calendar.frame =
        CGRectMake(self.mdWidth / 2, 0, self.mdWidth / 2, self.mdHeight);
  } break;
  case UIInterfaceOrientationUnknown:
    break;
  }
}

- (void)setDelegate:(id)delegate {
  _delegate = delegate;
  _calendar.delegate = delegate;
}

@end