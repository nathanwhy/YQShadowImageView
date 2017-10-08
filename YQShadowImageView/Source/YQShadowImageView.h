//
//  YQShadowImageView.h
//  YQShadowImageView
//
//  Created by nathan on 2017/10/8.
//  Copyright © 2017年 nathanwhy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YQShadowImageView : UIView

/**
 Gaussian Blur radius, larger will make the back ground shadow lighter (warning: do not set it too large, 2 or 3 for most cases)
 */
@property (nonatomic, assign) IBInspectable CGFloat blurRadius;

/**
 The image view contains target image
 */
@property (nonatomic, strong) IBInspectable UIImage *image;

/**
 Image's corner radius
 */
@property (nonatomic, assign) IBInspectable CGFloat imageCornerRaidus;

/**
 shadow radius offset in percentage, if you want shadow radius larger, set a postive number for this, if you want it be smaller, then set a negative number
 */
@property (nonatomic, assign) IBInspectable CGFloat shadowRadiusOffSetPercentage;

/**
 Shadow offset value on x axis, postive -> right, negative -> left
 */
@property (nonatomic, assign) IBInspectable CGFloat shadowOffSetByX;

/**
 Shadow offset value on y axis, postive -> right, negative -> left
 */
@property (nonatomic, assign) IBInspectable CGFloat shadowOffSetByY;

/**
 Shadow alpha value
 */
@property (nonatomic, assign) IBInspectable CGFloat shadowAlpha;

/**
 store cache shadow image
 */
@property (nonatomic, copy, nullable) void (^cacheShadowImage)(UIImage *image);

/**
 get cache shadow image
 */
@property (nonatomic, copy, nullable) UIImage* (^getCacheShadowImage)(void);

@end

NS_ASSUME_NONNULL_END
