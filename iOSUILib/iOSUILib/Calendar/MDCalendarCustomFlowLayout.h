//
//  MDCalendarCustomFlowLayout.h
//  iOSUILibDemo
//
//  Created by Артур Сагидулин on 19.04.16.
//  Copyright © 2016 FPT Software. All rights reserved.
//

#define ISIPHONE_4 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )480.0 ) < DBL_EPSILON )
#define ISIPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568.0 ) < DBL_EPSILON )
#define ISIPHONE_6 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )667.0 ) < DBL_EPSILON )
#define ISIPHONE_6_PLUS ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )736.0 ) < DBL_EPSILON )


#import <UIKit/UIKit.h>

@interface MDCalendarCustomFlowLayout : UICollectionViewFlowLayout

@end
