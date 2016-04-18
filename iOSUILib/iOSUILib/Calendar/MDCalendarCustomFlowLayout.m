//
//  MDCalendarCustomFlowLayout.m
//  iOSUILibDemo
//
//  Created by Артур Сагидулин on 19.04.16.
//  Copyright © 2016 FPT Software. All rights reserved.
//

#import "MDCalendarCustomFlowLayout.h"

@implementation MDCalendarCustomFlowLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    CGSize cellSize = CGSizeMake(49, 50);
    self.itemSize = cellSize;
    self.estimatedItemSize = cellSize;
    
    self.minimumInteritemSpacing = 0;
    self.minimumLineSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
    //self.sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
}

- (void)awakeFromNib
{
    [self setup];
}

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
//    
//    CGFloat approximatePage = self.collectionView.contentOffset.y / self.pageHeight;
////    CGFloat currentPage = (velocity.y < 0.0) ? floor(approximatePage) : ceil(approximatePage);
////    
////    NSInteger flickedPages = ceil(velocity.y / self.flickVelocity);
////    
////    if (flickedPages) {
////        proposedContentOffset.y = (currentPage + flickedPages) * self.pageHeight;
////    } else {
////        proposedContentOffset.y = currentPage * self.pageHeight;
////    }
//    if (velocity.y < 0.0) {
//        proposedContentOffset.y = self.collectionView.contentOffset.y - [self pageHeight];
//    } else if (velocity.y > 0.0) {
//        proposedContentOffset.y = self.collectionView.contentOffset.y + [self pageHeight];
//    }
//    return proposedContentOffset;
//}
//
//- (CGFloat)pageHeight {
//    return (56/7)*50;//self.itemSize.height + self.minimumLineSpacing;
//}
//
//- (CGFloat)flickVelocity {
//    return .3;
//}
@end
