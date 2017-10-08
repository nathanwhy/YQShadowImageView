//
//  YQShadowImageView.m
//  YQShadowImageView
//
//  Created by nathan on 2017/10/8.
//  Copyright © 2017年 nathanwhy. All rights reserved.
//

#import "YQShadowImageView.h"


CGSize YQShadowImageScaled(CGFloat percentage, CGSize size) {
    return CGSizeMake(size.width * percentage, size.height * percentage);
}


@interface UIImage (YQShadowImage)

- (UIImage *)resizedWithPercentage:(CGFloat)percentage;
- (instancetype)initWithLayer:(CALayer *)layer;

@end

@interface YQShadowImageView()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *blurredImageView;

@end

@implementation YQShadowImageView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    _blurRadius = 3;
    _shadowAlpha = 1;
    self.imageView = [[UIImageView alloc] init];
    self.blurredImageView = [[UIImageView alloc] init];
    self.contentMode = UIViewContentModeScaleAspectFit;
    
    self.imageView.image = self.image;
    self.imageView.frame = self.bounds;
    self.imageView.layer.cornerRadius = self.imageCornerRaidus;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.contentMode = self.contentMode;
    [self addSubview:self.blurredImageView];
    [self addSubview:self.imageView];
    [self sendSubviewToBack:self.blurredImageView];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)setBlurRadius:(CGFloat)blurRadius {
    if (_blurRadius != blurRadius) {
        _blurRadius = blurRadius;
        [self layoutShadow];
    }
}

- (void)setImage:(UIImage *)image {
    if (_image != image) {
        _image = image;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
            [self layoutShadow];
        });
    }
}

- (void)setImageCornerRaidus:(CGFloat)imageCornerRaidus {
    if (_imageCornerRaidus != imageCornerRaidus) {
        _imageCornerRaidus = imageCornerRaidus;
        self.imageView.layer.cornerRadius = imageCornerRaidus;
        self.imageView.layer.masksToBounds = YES;
    }
}

- (void)setShadowRadiusOffSetPercentage:(CGFloat)shadowRadiusOffSetPercentage {
    if (_shadowRadiusOffSetPercentage != shadowRadiusOffSetPercentage) {
        _shadowRadiusOffSetPercentage = shadowRadiusOffSetPercentage;
        [self layoutShadow];
    }
}

- (void)setShadowOffSetByX:(CGFloat)shadowOffSetByX {
    if (_shadowOffSetByX != shadowOffSetByX) {
        _shadowOffSetByX = shadowOffSetByX;
        [self layoutShadow];
    }
}

- (void)setShadowOffSetByY:(CGFloat)shadowOffSetByY {
    if (_shadowOffSetByY != shadowOffSetByY) {
        _shadowOffSetByY = shadowOffSetByY;
        [self layoutShadow];
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    [self layoutShadow];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutShadow];
}

#pragma mark - private

- (void)generateBlurBackground {
    if (!self.image) {
        return;
    }
    CGSize realImageSize = [self getRealImageSizeWithImage:self.image];
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
    dispatch_queue_t queue = dispatch_queue_create("com.yunqi.user-interactive", attr);
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(queue, ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        
        UIImage *blurredImage = nil;
        
        if (self.getCacheShadowImage) {
            blurredImage = self.getCacheShadowImage();
        }
        if (!blurredImage) {
            CALayer *containerLayer = [CALayer layer];
            
            CGSize scaleSize = YQShadowImageScaled(1.4, realImageSize);
            containerLayer.frame = CGRectMake(0, 0, scaleSize.width, scaleSize.height);
            containerLayer.backgroundColor = [UIColor clearColor].CGColor;
            
            CALayer *blurImageLayer = [CALayer layer];
            blurImageLayer.frame = CGRectMake(realImageSize.width * 0.2, realImageSize.height * 0.2, realImageSize.width, realImageSize.height);
            blurImageLayer.contents = (__bridge id)strongSelf.image.CGImage;
            blurImageLayer.cornerRadius = strongSelf.imageCornerRaidus;
            blurImageLayer.masksToBounds = YES;
            [containerLayer addSublayer:blurImageLayer];
            
            UIImage *containerImage = nil;
            if (!CGSizeEqualToSize(containerLayer.frame.size, CGSizeZero)) {
                containerImage = [[UIImage alloc] initWithLayer:containerLayer];
            } else {
                containerImage = [[UIImage alloc] init];
            }
            
            UIImage *resizedContainerImage = [containerImage resizedWithPercentage:0.2];
            blurredImage = [strongSelf appleBlurWithImage:resizedContainerImage];
            
            if (self.cacheShadowImage) {
                self.cacheShadowImage(blurredImage);
            }
        }
        
        if (!blurredImage) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.blurredImageView.alpha = 0.01;
            self.blurredImageView.image = blurredImage;
            [UIView animateWithDuration:0.5 animations:^{
                self.blurredImageView.alpha = 1.0;
            }];
        });
    });
}

- (UIImage *)appleBlurWithImage:(UIImage *)image {
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:@(self.blurRadius) forKey:kCIInputRadiusKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef outImage = [context createCGImage:result fromRect:[inputImage extent]];
    UIImage *blurImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    return blurImage;
}

- (CGSize)getRealImageSizeWithImage:(UIImage *)fromImage {
    if (self.contentMode == UIViewContentModeScaleAspectFit) {
        CGFloat scale = MIN(self.bounds.size.width / fromImage.size.width, self.bounds.size.height / fromImage.size.height);
        return YQShadowImageScaled(scale, fromImage.size);
    } else {
        return fromImage.size;
    }
}

- (void)layoutShadow {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateBlurBackground];
        if (!self.image) {
            return;
        }
        CGSize realImageSize = [self getRealImageSizeWithImage:self.image];
        
        self.imageView.frame = CGRectMake(0, 0, realImageSize.width, realImageSize.height);
        self.imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        
        CGSize newSize = YQShadowImageScaled(1.4 * (1 + self.shadowRadiusOffSetPercentage / 100.), realImageSize);
        
        self.blurredImageView.frame = CGRectMake(0, 0, newSize.width, newSize.height);
        self.blurredImageView.center = CGPointMake(self.bounds.size.width / 2.0 + self.shadowOffSetByX, self.bounds.size.height / 2 + self.shadowOffSetByY);
        self.blurredImageView.contentMode = self.contentMode;
        self.blurredImageView.alpha = self.shadowAlpha;
    });
}

@end


@implementation UIImage (YQShadowImage)

- (UIImage *)resizedWithPercentage:(CGFloat)percentage {
    CGSize canvasSize = YQShadowImageScaled(percentage, self.size);
    UIGraphicsBeginImageContextWithOptions(canvasSize, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, canvasSize.width, canvasSize.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (instancetype)initWithLayer:(CALayer *)layer {
    UIGraphicsBeginImageContext(layer.frame.size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image) {
        return [self initWithCGImage:image.CGImage];
    } else {
        return [self init];
    }
}

@end
