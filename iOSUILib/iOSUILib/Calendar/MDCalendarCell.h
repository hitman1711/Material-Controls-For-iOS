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

#import <UIKit/UIKit.h>
#import "MDCalendar.h"
NS_ASSUME_NONNULL_BEGIN
@interface MDCalendarCell : UICollectionViewCell

@property(strong,nonatomic) UIView *separator;

@property(weak, nonatomic) NSDictionary <NSNumber*, UIColor*>* titleColors;
@property(weak, nonatomic) NSDictionary <NSNumber*, UIColor*>* backgroundColors;

@property(copy, nonatomic, nullable) NSArray* contactsIds;

@property(copy, nonatomic) NSDate* date;
@property(copy, nonatomic) NSDate* month;
@property(weak, nonatomic) NSDate* currentDate;

@property(weak, nonatomic) UILabel* titleLabel;

@property(assign, nonatomic) MDCalendarCellStyle cellStyle;

@property(readonly, getter=isPlaceholder) BOOL placeholder;
@property(assign, getter=isShowPlaceholder) BOOL showPlaceholder;

- (void)showAnimation;
- (void)hideAnimation;
- (void)configureCell;

- (BOOL)isToday;

@end
NS_ASSUME_NONNULL_END