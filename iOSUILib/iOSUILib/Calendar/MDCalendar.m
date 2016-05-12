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

#import "MDCalendar.h"
#import "MDCalendarCell.h"
#import "MDCalendarHeader.h"
#import "MDCalendarYearSelector.h"
#import "NSCalendarHelper.h"
#import "NSDate+MDExtension.h"
#import "NSDateHelper.h"
#import "UIColorHelper.h"
#import "UIFontHelper.h"
#import "UIView+MDExtension.h"
#import "MDCalendarCustomFlowLayout.h"


@interface MDCalendar (DataSourceAndDelegate)

- (void)didSelectDate:(NSDate *)date;

@end

@interface MDCalendar () <UICollectionViewDataSource, UICollectionViewDelegate,
                          MDCalendarDateHeaderDelegate,
                          MDCalendarYearSelectorDelegate,UICollectionViewDelegateFlowLayout>

@property(strong, nonatomic) NSArray *weekdays;

@property(strong, nonatomic) NSMutableDictionary *backgroundThemeColors;
@property(strong, nonatomic) NSMutableDictionary *titleThemeColors;

@property(weak, nonatomic) UICollectionView *collectionView;
@property(weak, nonatomic) UICollectionViewFlowLayout *collectionViewFlowLayout;

@property(copy, nonatomic) NSDate *maximumDate;

@property(nonatomic) MDCalendarCellStyle cellStyle;

@property(weak, nonatomic) MDCalendarYearSelector *yearSelector;

@property(strong, nonatomic) UIFont *titleFont UI_APPEARANCE_SELECTOR;
@property(strong, nonatomic) UIFont *titleMonthFont UI_APPEARANCE_SELECTOR;

@property(nonatomic, assign) BOOL hadRemoveObserver;
@property(nonatomic) BOOL isDoingLayoutSubview;

@property (nonatomic) CGFloat scrollStartY;

- (void)initThemeColors;

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForDate:(NSDate *)date;

- (void)scrollToDate:(NSDate *)date;

@end

@implementation MDCalendar

@synthesize theme = _theme;
@synthesize firstWeekday = _firstWeekday;

#pragma mark - Life Cycle && Initialize

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self initialize];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self initialize];
  }
  return self;
}

- (void)initialize {
  _showPlaceholder = NO;
  _titleFont = [UIFontHelper robotoFontOfSize:15];
  _titleMonthFont = [UIFontHelper robotoFontWithName:@"CoreSansDS55Bold" size:15];
  [self initThemeColors];
  _theme = -1;
  _isDoingLayoutSubview = NO;

  _weekdays =
      [[NSCalendarHelper mdSharedCalendar] shortStandaloneWeekdaySymbols];

  _firstWeekday = [[NSCalendarHelper mdSharedCalendar] firstWeekday];

    MDCalendarCustomFlowLayout *collectionViewFlowLayout = [[MDCalendarCustomFlowLayout alloc] init];
  self.collectionViewFlowLayout = collectionViewFlowLayout;

  UICollectionView *collectionView =
      [[UICollectionView alloc] initWithFrame:CGRectZero
                         collectionViewLayout:collectionViewFlowLayout];
  collectionView.dataSource = self;
  collectionView.delegate = self;
  collectionView.backgroundColor = [UIColor clearColor];
  collectionView.bounces = YES;
    collectionView.pagingEnabled =  NO; //YES;
  collectionView.showsHorizontalScrollIndicator = NO;
  collectionView.showsVerticalScrollIndicator = NO;
  collectionView.delaysContentTouches = NO;
  collectionView.canCancelContentTouches = YES;
  [collectionView registerClass:[MDCalendarCell class]
      forCellWithReuseIdentifier:@"cell"];
  [collectionView registerClass:[UICollectionViewCell class]
      forCellWithReuseIdentifier:@"week"];
  [collectionView registerClass:[UICollectionViewCell class]
      forCellWithReuseIdentifier:@"month"];
  [self addSubview:collectionView];
  [collectionView
      addObserver:self
       forKeyPath:@"contentSize"
          options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
          context:nil];
  self.collectionView = collectionView;

  _currentDate = [NSDate date];
  _currentMonth = [_currentDate copy];

  _cellStyle = MDCalendarCellStyleCircle;

  self.minimumDate = [NSDateHelper mdDateWithYear:2010 month:1 day:1];
  _maximumDate = [NSDateHelper mdDateWithYear:2037 month:12 day:31];

  MDCalendarYearSelector *yearSelector =
      [[MDCalendarYearSelector alloc] initWithFrame:self.collectionView.frame
                                    withMiniminDate:self.minimumDate
                                     andMaximumDate:_maximumDate];
  _yearSelector = yearSelector;
  _yearSelector.delegate = self;
  _yearSelector.hidden = YES;

  [self setSelectedDate:_currentDate]; // default selected date is current: #15

  [self.yearSelector relayout];
  [self addSubview:_yearSelector];
}

- (void)initThemeColors {
    _backgroundThemeColors = [NSMutableDictionary dictionaryWithCapacity:3];//2
    
    
    NSMutableDictionary *backgroundColorsLight =
    [NSMutableDictionary dictionaryWithCapacity:5];
    backgroundColorsLight[@(MDCalendarCellStateNormal)] = [UIColor clearColor];
    backgroundColorsLight[@(MDCalendarCellStateSelected)] =
    [UIColorHelper colorWithRGBA:@"#009688"];
    backgroundColorsLight[@(MDCalendarCellStateDisabled)] = [UIColor clearColor];
    backgroundColorsLight[@(MDCalendarCellStatePlaceholder)] =
    [UIColor clearColor];
    backgroundColorsLight[@(MDCalendarCellStateToday)] = [UIColor clearColor];
    
    NSMutableDictionary *backgroundColorsDark =
    [NSMutableDictionary dictionaryWithCapacity:5];
    backgroundColorsDark[@(MDCalendarCellStateNormal)] =
    [UIColorHelper colorWithRGBA:@"#263238"];
    backgroundColorsDark[@(MDCalendarCellStateSelected)] =
    [UIColorHelper colorWithRGBA:@"#80deea"];
    backgroundColorsDark[@(MDCalendarCellStateDisabled)] = [UIColor clearColor];
    backgroundColorsDark[@(MDCalendarCellStatePlaceholder)] =
    [UIColor clearColor];
    backgroundColorsDark[@(MDCalendarCellStateToday)] = [UIColor clearColor];
    
    
    NSMutableDictionary *backgroundColorsCustom = [NSMutableDictionary dictionaryWithCapacity:5];
    backgroundColorsCustom[@(MDCalendarCellStateNormal)] = [UIColor clearColor];
    backgroundColorsCustom[@(MDCalendarCellStateSelected)] =
    [UIColorHelper colorWithRGBA:@"#253e8e"];
    backgroundColorsCustom[@(MDCalendarCellStateDisabled)] = [UIColor clearColor];
    backgroundColorsCustom[@(MDCalendarCellStatePlaceholder)] =
    [UIColor clearColor];
    backgroundColorsCustom[@(MDCalendarCellStateToday)] = [UIColor clearColor];
    //backgroundColorsCustom[@(MDCalendarCellStateWeekend)] = [UIColor redColor];
    
    
    _backgroundThemeColors[@(MDCalendarThemeLight)] = backgroundColorsLight;
    _backgroundThemeColors[@(MDCalendarThemeDark)] = backgroundColorsDark;
    _backgroundThemeColors[@(MDCalendarThemeCustom)] = backgroundColorsCustom;
    
    
    NSMutableDictionary *titleColorsLight =
    [NSMutableDictionary dictionaryWithCapacity:8];
    titleColorsLight[@(MDCalendarCellStateNormal)] = [UIColor darkTextColor];
    titleColorsLight[@(MDCalendarCellStateSelected)] = [UIColor whiteColor];
    titleColorsLight[@(MDCalendarCellStateDisabled)] = [UIColor clearColor];
    titleColorsLight[@(MDCalendarCellStatePlaceholder)] = [UIColor clearColor];
    titleColorsLight[@(MDCalendarCellStateToday)] =
    [UIColorHelper colorWithRGBA:@"#009284"];
    titleColorsLight[@(MDCalendarCellStateWeekTitle)] = [UIColor lightGrayColor];
    titleColorsLight[@(MDCalendarCellStateMonthTitle)] = [UIColor blackColor];
    titleColorsLight[@(MDCalendarCellStateButton)] = [UIColor blackColor];
    
    NSMutableDictionary *titleColorsDark =
    [NSMutableDictionary dictionaryWithCapacity:8];
    titleColorsDark[@(MDCalendarCellStateNormal)] = [UIColor whiteColor];
    titleColorsDark[@(MDCalendarCellStateSelected)] = [UIColor whiteColor];
    titleColorsDark[@(MDCalendarCellStateDisabled)] = [UIColor clearColor];
    titleColorsDark[@(MDCalendarCellStatePlaceholder)] = [UIColor clearColor];
    titleColorsDark[@(MDCalendarCellStateToday)] =
    [UIColorHelper colorWithRGBA:@"#80deea"];
    titleColorsDark[@(MDCalendarCellStateWeekTitle)] = [UIColor lightGrayColor];
    titleColorsDark[@(MDCalendarCellStateMonthTitle)] = [UIColor whiteColor];
    titleColorsDark[@(MDCalendarCellStateButton)] = [UIColor whiteColor];
    
    NSMutableDictionary *titleColorsCustom =
    [NSMutableDictionary dictionaryWithCapacity:8];
    titleColorsCustom[@(MDCalendarCellStateNormal)] = [UIColorHelper colorWithRGBA:@"#333333"];    titleColorsCustom[@(MDCalendarCellStateSelected)] = [UIColor whiteColor];
    titleColorsCustom[@(MDCalendarCellStateDisabled)] = [UIColor clearColor];
    titleColorsCustom[@(MDCalendarCellStatePlaceholder)] = [UIColor clearColor];
    titleColorsCustom[@(MDCalendarCellStateToday)] =
    [UIColorHelper colorWithRGBA:@"#009284"];
    titleColorsCustom[@(MDCalendarCellStateWeekTitle)] = [UIColorHelper colorWithRGBA:@"#1e1e1e"];    titleColorsCustom[@(MDCalendarCellStateMonthTitle)] = [UIColorHelper colorWithRGBA:@"#1c1c1c"];    titleColorsCustom[@(MDCalendarCellStateButton)] = [UIColor blackColor];
    titleColorsCustom[@(MDCalendarCellStateWeekend)] = [UIColorHelper colorWithRGBA:@"#e674a7"];
    
    _titleThemeColors = [NSMutableDictionary dictionaryWithCapacity:3];//2
    _titleThemeColors[@(MDCalendarThemeLight)] = titleColorsLight;
    _titleThemeColors[@(MDCalendarThemeDark)] = titleColorsDark;
    _titleThemeColors[@(MDCalendarThemeCustom)] = titleColorsCustom;
}

- (void)setTheme:(MDCalendarTheme)theme {
  if (_theme != theme) {
    _theme = theme;
    _backgroundColors = _backgroundThemeColors[@(_theme)];
    _titleColors = _titleThemeColors[@(_theme)];
    UIColor *bgColor;
    if (_theme == MDCalendarThemeDark) {
      bgColor = [UIColorHelper colorWithRGBA:@"#263238"];
    } else if (_theme == MDCalendarThemeLight) {
      bgColor = [UIColor whiteColor];
    } else if (_theme == MDCalendarThemeCustom) {
        bgColor = [UIColor whiteColor];
    }

    [self setBackgroundColor:bgColor];

    if (_dateHeader) {
      _dateHeader.theme = _theme;
    }
    if (_yearSelector) {
      [_yearSelector setBackgroundColor:bgColor];
      _yearSelector.titleColors = _titleColors;
      _yearSelector.backgroundColors = _backgroundColors;
    }
    [self reloadData];
  }
}

- (void)layoutSubviews {
  _isDoingLayoutSubview = YES;
  NSDate *currentDate = _currentMonth;
  _dateHeader.dateFormatter.dateFormat = @"dd-MM-yyyy";

  [super layoutSubviews];
  _collectionView.frame = CGRectMake(0, 0, self.mdWidth, self.mdHeight);
  [self.collectionView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];

  _yearSelector.frame = _collectionView.frame;

  [self reloadData];
  [self.yearSelector relayout];
  _dateHeader.dateFormatter.dateFormat = @"dd-MM-yyyy";
  [self scrollToDate:currentDate];
  _isDoingLayoutSubview = NO;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat itemWidth = floorf(CGRectGetWidth(self.collectionView.bounds) / 7);
    CGFloat itemHeight = (ISIPHONE_4 || ISIPHONE_6) ? 50 : 62;
    return CGSizeMake(itemWidth, itemHeight);
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"contentSize"]) {
    if (!_isDoingLayoutSubview) {
      [self scrollToDate:_currentMonth];
    }
    [_collectionView removeObserver:self forKeyPath:@"contentSize"];
    _hadRemoveObserver = true;
  }
}

#pragma mark - UICollectionView dataSource/delegate

- (NSInteger)numberOfSectionsInCollectionView:
    (UICollectionView *)collectionView {
  return [_maximumDate mdMonthsFrom:self.minimumDate] + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  // NSLog(@"collectionView numberOfItemsInSection %li", section);
  return 56; // 42 + (rand() % 3) * 7;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM"];
    
    
    if (indexPath.item >= 0 && indexPath.item <= 6) {
        
        UICollectionViewCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:@"week"//@"month"
                                                  forIndexPath:indexPath];
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:110];
        if (!titleLabel) {
            titleLabel = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
            titleLabel.frame = cell.contentView.bounds;
            titleLabel.tag = 110;
            
            [titleLabel setTextColor:_titleColors[@(MDCalendarCellStateWeekTitle)]];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:titleLabel];
        }
        titleLabel.font = self.titleFont;
        // titleLabel.text = [NSString stringWithFormat:@"W%li", indexPath.item];
        titleLabel.text =
        [_weekdays objectAtIndex:(indexPath.item + _firstWeekday - 1) % 7];
        
        return cell;
    } else if (indexPath.item == 7){//(indexPath.item >= 7 && indexPath.item <= 13) {
        UICollectionViewCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:@"month"//@"week"
                                                  forIndexPath:indexPath];
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        if (!titleLabel) {
            titleLabel = [[UILabel alloc]
                          initWithFrame:CGRectMake(0, 0, self.mdWidth, cell.mdHeight)];
            titleLabel.tag = 100;
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [titleLabel setFont:_titleMonthFont];
            [titleLabel setTextColor:_titleColors[@(MDCalendarCellStateMonthTitle)]];
            [cell.contentView addSubview:titleLabel];
        }
        // titleLabel.mdWidth = self.mdWidth;
        _dateHeader.dateFormatter.dateFormat = @"LLLL";
        titleLabel.text = [[_dateHeader.dateFormatter
                            stringFromDate:[self.minimumDate
                                            mdDateByAddingMonths:indexPath.section]] uppercaseString];
        return cell;
    } else {//if (indexPath.item > 7) {
        
        MDCalendarCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                  forIndexPath:indexPath];
        // NSLog(@"cellForItemAtIndexPath %li", indexPath.item);
        
        NSDate *currentDate = [self dateForIndexPath:indexPath];
        
        NSString *currentShortDate = [self shortTextStringFormDate:currentDate];
        NSString *currentDateString = [self textStringFormDate:currentDate];
        
        NSArray *allShortDates = [_shortDatesDict allKeys];
        
        NSMutableArray *idsTempArray = [NSMutableArray new];
        
        BOOL isAnnual = YES;
        BOOL hasDate = NO;
        for (int i=0; i<allShortDates.count; i++) {
            NSString *iDateStr = allShortDates[i];
            isAnnual = iDateStr.length<=5 ? YES : NO;
            NSString *appropriateDateString = isAnnual ? currentShortDate : currentDateString;
            
            if ([iDateStr isEqualToString:appropriateDateString]) {
                hasDate = YES;
                [idsTempArray addObjectsFromArray:[_shortDatesDict valueForKey:iDateStr]];
            }
        }
        if (hasDate) {
            cell.contactsIds = idsTempArray;
        } else {
            cell.contactsIds = nil;
        }

        
        cell.titleColors = self.titleColors;
        cell.backgroundColors = self.backgroundColors;
        cell.cellStyle = self.cellStyle;
        cell.month = [self.minimumDate mdDateByAddingMonths:indexPath.section];
        cell.currentDate = self.currentDate;
        cell.titleLabel.font = _titleFont;
        cell.date = currentDate;
        cell.showPlaceholder = _showPlaceholder;
        
        return cell;
        
    }
}

- (NSString*)shortTextStringFormDate:(NSDate*)date
{
    static NSDateFormatter *shortTextFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortTextFormatter = [[NSDateFormatter alloc] init];
        [shortTextFormatter setDateFormat:@"dd.MM"];
    });
    return [shortTextFormatter stringFromDate:date];
}

- (NSString*)textStringFormDate:(NSDate*)date
{
    static NSDateFormatter *shortTextFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortTextFormatter = [[NSDateFormatter alloc] init];
        [shortTextFormatter setDateFormat:@"dd.MM.yyyy"];
    });
    return [shortTextFormatter stringFromDate:date];
}



-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.item >= 0 && indexPath.item <= 6) {
        
        UILabel *titleLabel = [cell viewWithTag:110];
        MDCalendarCellState colorCellState = indexPath.item >=5 ? MDCalendarCellStateWeekend : MDCalendarCellStateWeekTitle;
        [titleLabel setTextColor:_titleColors[@(colorCellState)]];
        
    } else if (indexPath.item > 7) {
        
        MDCalendarCell* cCell = (MDCalendarCell*)cell;
        
        NSDate *currentDate = [self dateForIndexPath:indexPath];
        NSDateComponents *currentComponents = [[NSCalendar currentCalendar] components: NSCalendarUnitMonth  fromDate:currentDate];
        NSDateComponents *monthComponents = [[NSCalendar currentCalendar] components: NSCalendarUnitMonth  fromDate:cCell.month];
        NSInteger currentMonth = [currentComponents month];
        NSInteger mMonth = [monthComponents month];
        if (currentMonth!=mMonth) {
            [cCell.separator setHidden:YES];
        } else {
            [cCell.separator setHidden:NO];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.item >= 0 && indexPath.item <= 6) {
        // week title
        NSIndexPath *newIndexPath =
        [NSIndexPath indexPathForItem:(indexPath.item + 7)
                            inSection:indexPath.section];
        [_collectionView selectItemAtIndexPath:newIndexPath
                                      animated:NO
                                scrollPosition:UICollectionViewScrollPositionNone];
        [self collectionView:_collectionView didSelectItemAtIndexPath:newIndexPath];
        
    } else if (indexPath.item >= 8 && indexPath.item <= 14) {
        return; // do nothing - month title
    }  else {
        MDCalendarCell *cell =
        (MDCalendarCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if (cell.isPlaceholder) {
            indexPath = [self indexPathForDate:_selectedDate];
            cell =
            (MDCalendarCell *)[collectionView cellForItemAtIndexPath:indexPath];
            [_collectionView
             selectItemAtIndexPath:indexPath
             animated:NO
             scrollPosition:UICollectionViewScrollPositionNone];
        }
        NSDate *date = [self dateForIndexPath:indexPath];
        [cell showAnimation];
        _selectedDate = date;
        [self didSelectDate:_selectedDate];
        
        if (cell.contactsIds) {
            [_eventsDelegate calendar:self didSelectDateWithIds:cell.contactsIds];
        }

    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView
    shouldSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath;
{
    NSDate *date = [self dateForIndexPath:indexPath];
    
    MDCalendarCell *cell =
    (MDCalendarCell *)[collectionView cellForItemAtIndexPath:indexPath];
    BOOL shouldSelect = NO;
    
    if (cell.contactsIds) {
        [cell animateEventTapped];
        shouldSelect=NO;
        [_eventsDelegate calendar:self didSelectDateWithIds:cell.contactsIds];
    } else if (cell.isToday && [self shouldSelectDate:date]) {
        shouldSelect = YES;
    }
    
    NSLog(@"Should select:%@\n?:%i",date,shouldSelect);
    return shouldSelect;
}

- (void)collectionView:(UICollectionView *)collectionView
    didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item <= 13) {
    return;
  }
  MDCalendarCell *cell =
      (MDCalendarCell *)[collectionView cellForItemAtIndexPath:indexPath];
//    if (cell.isToday) {
        [cell hideAnimation];
//    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (_isDoingLayoutSubview) {
    return;
  }
    CGFloat itemHeight = (ISIPHONE_4 || ISIPHONE_6) ? 50 : 62;
    CGFloat scrollOffset =MAX(scrollView.contentOffset.x / scrollView.mdWidth,
                              scrollView.contentOffset.y / ((56/7)*itemHeight));

    //MAX(scrollView.contentOffset.x / scrollView.mdWidth,
    //                         scrollView.contentOffset.y / scrollView.mdHeight);

  NSDate *currentMonth =
      [self.minimumDate mdDateByAddingMonths:round(scrollOffset)];
  if (![_currentMonth mdIsEqualToDateForMonth:currentMonth]) {
    _currentMonth = [currentMonth copy];
    //[self currentMonthDidChange];
  }
}

//-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
//    
//}
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
//    NSLog(@"BEGIN Y:%f",scrollView.contentOffset.y);
//    _scrollStartY = scrollView.contentOffset.y;
//}
//
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
//    
//    NSLog(@"SV VELOCITY Y:%f",velocity.y);
//   // *targetContentOffset = //scrollView.contentOffset; // set acceleration to 0.0
////    float pageWidth = (float)371.;
////    int minSpace = 10;
////    BOOL isDownDirection = targetContentOffset.y > scrollView.contentOffset.y;
////    int sectionToSwipe = (scrollView.contentOffset.y)/pageWidth + 0.5; // cell width + min spacing for lines
////    if (sectionToSwipe < 0) {
////        cellToSwipe = 0;
////    } else if (cellToSwipe >= self.articles.count) {
////        cellToSwipe = self.articles.count - 1;
////    }
////    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:cellToSwipe inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    NSLog(@"END Y:%f isDec:%i",scrollView.contentOffset.y, decelerate);
//    CGFloat diff = scrollView.contentOffset.y - _scrollStartY;
//    if (diff==0)
//        return;
//
//    BOOL isDownDirection = diff>0 ? NO : YES;
//    NSDate *toDate = isDownDirection ? [self.currentDate mdDateBySubtractingMonths:1] : [self.currentDate mdDateByAddingMonths:1];
//    [self scrollToDate:toDate];
////   
////    CGFloat scrollOffset =MAX(scrollView.contentOffset.x / scrollView.mdWidth,
////                              scrollView.contentOffset.y / 371.);
////    
////    NSDate *currentMonth =
////    [self.minimumDate mdDateByAddingMonths:round(scrollOffset)];
////    if (![_currentMonth mdIsEqualToDateForMonth:currentMonth]) {
////        _currentMonth = [currentMonth copy];
////        //[self currentMonthDidChange];
////    }
//    
//}

#pragma mark - Setter & Getter

- (void)setFirstWeekday:(NSUInteger)firstWeekday {
  if (_firstWeekday != firstWeekday) {
    _firstWeekday = firstWeekday;
    [[NSCalendarHelper mdSharedCalendar] setFirstWeekday:firstWeekday];
    [self reloadData];
  }
}

- (void)setMinimumDate:(NSDate *)minimumDate;
{
  NSDate *date =
      [[NSCalendarHelper mdSharedCalendar] startOfDayForDate:minimumDate];
  _minimumDate = date;
  self.yearSelector.minimumDate = date;
  [self.collectionView reloadData];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
  NSIndexPath *selectedIndexPath = [self indexPathForDate:selectedDate];
  if (![_selectedDate mdIsEqualToDateForDay:selectedDate]) {
    NSIndexPath *currentIndex =
        [_collectionView indexPathsForSelectedItems].lastObject;
    [_collectionView deselectItemAtIndexPath:currentIndex animated:NO];
    [self collectionView:_collectionView
        didDeselectItemAtIndexPath:currentIndex];
    [_collectionView selectItemAtIndexPath:selectedIndexPath
                                  animated:NO
                            scrollPosition:UICollectionViewScrollPositionNone];
    [self scrollToDate:selectedDate];
    [self collectionView:_collectionView
        didSelectItemAtIndexPath:selectedIndexPath];
    _currentMonth = _selectedDate;
  }
}

- (void)setCurrentDate:(NSDate *)currentDate {
  if (![_currentDate mdIsEqualToDateForDay:currentDate]) {
    _currentDate = [currentDate copy];
    _currentMonth = [currentDate copy];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self scrollToDate:_currentDate];
    });
  }
}

- (void)setCurrentMonth:(NSDate *)currentMonth {
  if (![_currentMonth mdIsEqualToDateForMonth:currentMonth]) {
    _currentMonth = [currentMonth copy];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self scrollToDate:_currentMonth];
      //[self currentMonthDidChange];
    });
  }
}

- (void)setDateHeader:(MDCalendarDateHeader *)dateHeader {
  if (_dateHeader != dateHeader) {
    _dateHeader = dateHeader;
    _dateHeader.delegate = self;
    [_dateHeader setDate:_currentDate];
  }
}

#pragma mark - Public

- (void)reloadData {
  NSIndexPath *selectedPath =
      [_collectionView indexPathsForSelectedItems].lastObject;
  [self reloadData:selectedPath];
}

#pragma mark - Private

- (void)scrollToDate:(NSDate *)date
{
    @try {
        //NSIndexPath *selectedDateIndexPath = [self indexPathForCellAtDate:date];
        NSInteger scrollOffset = [date mdMonthsFrom:self.minimumDate];
        NSIndexPath *selectedDateIndexPath = [NSIndexPath indexPathForItem:0 inSection:scrollOffset];
        
        if (![[self.collectionView indexPathsForVisibleItems] containsObject:selectedDateIndexPath]) {
            
            UICollectionViewLayoutAttributes *sectionLayoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:selectedDateIndexPath];
            CGPoint origin = sectionLayoutAttributes.frame.origin;
            origin.x = 0;
            //origin.y -= (PDTSimpleCalendarFlowLayoutInsetTop + self.collectionView.contentInset.top);
            [self.collectionView setContentOffset:origin animated:NO];
        }
    }
    @catch (NSException *exception) {
        //Exception occured (it should not according to the documentation, but in reality...) let's scroll to the IndexPath then
        NSInteger section = [date mdMonthsFrom:self.minimumDate];
        NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        [self.collectionView scrollToItemAtIndexPath:sectionIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath {
  NSDate *currentMonth =
      [self.minimumDate mdDateByAddingMonths:indexPath.section];
  NSDate *firstDayOfMonth = [NSDateHelper mdDateWithYear:currentMonth.mdYear
                                                   month:currentMonth.mdMonth
                                                     day:1];
  NSInteger numberOfPlaceholdersForPrev =
      ((firstDayOfMonth.mdWeekday - _firstWeekday) + 7) % 7
          ?: (self.showPlaceholder ? 7 : 0);
  numberOfPlaceholdersForPrev = numberOfPlaceholdersForPrev + 14;

  NSDate *firstDateOfPage =
      [firstDayOfMonth mdDateBySubtractingDays:numberOfPlaceholdersForPrev];
  NSDate *date = [firstDateOfPage mdDateByAddingDays:indexPath.item];
  return date;
}

- (NSIndexPath *)indexPathForDate:(NSDate *)date {
  NSInteger section = [date mdMonthsFrom:self.minimumDate];
  NSDate *firstDayOfMonth =
      [NSDateHelper mdDateWithYear:date.mdYear month:date.mdMonth day:1];
  NSInteger numberOfPlaceholdersForPrev =
      ((firstDayOfMonth.mdWeekday - _firstWeekday) + 7) % 7
          ?: (self.showPlaceholder ? 7 : 0);
  numberOfPlaceholdersForPrev = numberOfPlaceholdersForPrev + 14;
  NSDate *firstDateOfPage =
      [firstDayOfMonth mdDateBySubtractingDays:numberOfPlaceholdersForPrev];
  NSInteger item = item = [date mdDaysFrom:firstDateOfPage];
  return [NSIndexPath indexPathForItem:item inSection:section];
}

- (BOOL)shouldSelectDate:(NSDate *)date {
  BOOL result =
      (date.timeIntervalSince1970 >= self.minimumDate.timeIntervalSince1970);
  return result;
}

- (void)didSelectDate:(NSDate *)date {
  if ([self shouldSelectDate:date]) {
    if (_dateHeader) {
      [_dateHeader setDate:date];
    }

    [_delegate calendar:self didSelectDate:_selectedDate];
  }
}

- (void)reloadData:(NSIndexPath *)selection {
  [_collectionView reloadData];
  [_collectionView selectItemAtIndexPath:selection
                                animated:NO
                          scrollPosition:UICollectionViewScrollPositionNone];
}

#pragma MDCalendarDateHeaderDelegate

- (void)didSelectCalendar {
  self.collectionView.hidden = NO;
  self.yearSelector.hidden = YES;
}

- (void)didSelectYear {
  self.collectionView.hidden = YES;
  self.yearSelector.hidden = NO;
  self.yearSelector.currentYear =
      _selectedDate ? [_selectedDate mdYear] : [_currentDate mdYear];
}

#pragma MDCalendarYearSelectorDelegate

- (void)calendarYearDidSelected:(NSInteger)year {
  if (!_selectedDate)
    _selectedDate = _currentDate;

  NSCalendar *calendar = [NSCalendarHelper mdSharedCalendar];
  NSDateComponents *component = [calendar
      components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
        fromDate:_selectedDate];
  [component setYear:year];
  NSDate *_newSelectedDate = [calendar dateFromComponents:component];

  [self setSelectedDate:_newSelectedDate];

  [self didSelectCalendar];
  if (_dateHeader) {
    [_dateHeader showCalendar];
  }
}

- (void)dealloc {
  if (!_hadRemoveObserver) {
    [_collectionView removeObserver:self forKeyPath:@"contentSize" context:nil];
  }
}

@end
