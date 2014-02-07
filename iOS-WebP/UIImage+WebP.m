//
//  UIImage+WebP.m
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import "UIImage+WebP.h"

// This gets called when the UIImage gets collected and frees the underlying image.
static void free_image_data(void *info, const void *data, size_t size)
{
    if(info != NULL)
        WebPFreeDecBuffer(&(((WebPDecoderConfig *)info)->output));
    else
        free((void *)data);
}

@implementation UIImage (WebP)

#pragma mark - Private methods

+ (NSData *)convertToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha preset:(WebPPreset)preset error:(NSError **)error
{
    NSLog(@"WebP Encoder Version: %@", [self version:WebPGetEncoderVersion()]);
    
    if (alpha < 1) {
        image = [self webPImage:image withAlpha:alpha];
    }
    
    CGImageRef webPImageRef = image.CGImage;
    size_t webPBytesPerRow = CGImageGetBytesPerRow(webPImageRef);
    
    size_t webPImageWidth = CGImageGetWidth(webPImageRef);
    size_t webPImageHeight = CGImageGetHeight(webPImageRef);
    
    CGDataProviderRef webPDataProviderRef = CGImageGetDataProvider(webPImageRef);
    CFDataRef webPImageDatRef = CGDataProviderCopyData(webPDataProviderRef);
    
    uint8_t *webPImageData = (uint8_t *)CFDataGetBytePtr(webPImageDatRef);
    
    WebPConfig config;
    if (!WebPConfigPreset(&config, preset, quality)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Configuration preset failed to initialize." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        
        CFRelease(webPImageDatRef);
        return nil;
    }
    
    if (!WebPValidateConfig(&config)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"One or more configuration parameters are beyond their valid ranges." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        
        CFRelease(webPImageDatRef);
        return nil;
    }
    
    WebPPicture pic;
    if (!WebPPictureInit(&pic)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to initialize structure. Version mismatch." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        
        CFRelease(webPImageDatRef);
        return nil;
    }
    pic.width = (int)webPImageWidth;
    pic.height = (int)webPImageHeight;
    pic.colorspace = WEBP_YUV420;
    
    WebPPictureImportRGBA(&pic, webPImageData, (int)webPBytesPerRow);
    WebPPictureARGBToYUVA(&pic, WEBP_YUV420);
    WebPCleanupTransparentArea(&pic);
    
    WebPMemoryWriter writer;
    WebPMemoryWriterInit(&writer);
    pic.writer = WebPMemoryWrite;
    pic.custom_ptr = &writer;
    WebPEncode(&config, &pic);
    
    NSData *webPFinalData = [NSData dataWithBytes:writer.mem length:writer.size];
    
    WebPPictureFree(&pic);
    CFRelease(webPImageDatRef);
    
    return webPFinalData;
}

+ (UIImage *)convertFromWebP:(NSString *)filePath error:(NSError **)error
{
    NSLog(@"WebP Decoder Version: %@", [self version:WebPGetDecoderVersion()]);
    
    // If passed `filepath` is invalid, return nil to caller and log error in console
    NSError *dataError = nil;;
    NSData *imgData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&dataError];
    if(dataError != nil) {
        NSLog(@"imageFromWebP: error: %@", dataError.localizedDescription);
        return nil;
    }
    
    // `WebPGetInfo` weill return image width and height
    int width = 0, height = 0;
    if(!WebPGetInfo([imgData bytes], [imgData length], &width, &height)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Header formatting error." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    WebPDecoderConfig config;
    if(!WebPInitDecoderConfig(&config)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to initialize structure. Version mismatch." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    config.options.no_fancy_upsampling = 1;
    config.options.bypass_filtering = 1;
    config.options.use_threads = 1;
    config.output.colorspace = MODE_RGBA;
    
    // Decode the WebP image data into a RGBA value array
    VP8StatusCode decodeStatus = WebPDecode([imgData bytes], [imgData length], &config);
    if (decodeStatus != VP8_STATUS_OK) {
        NSString *errorString = [self statusForVP8Code:decodeStatus];
        
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:errorString forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain",  [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    // Construct UIImage from the decoded RGBA value array
    CGDataProviderRef provider = CGDataProviderCreateWithData(&config, config.output.u.RGBA.rgba, config.options.scaled_width  * config.options.scaled_height * 4, free_image_data);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault |kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    
    // Free resources to avoid memory leaks
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    WebPFreeDecBuffer(&config.output);
    
    return result;
}

#pragma mark - Synchronous methods
+ (UIImage *)imageFromWebP:(NSString *)filePath
{
    NSAssert(image != nil, @"imageToWebP:quality: image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality: quality has to be [0, 100]");
    
    return [self convertFromWebP:filePath error:nil];
}

+ (NSData *)imageToWebP:(UIImage *)image quality:(CGFloat)quality
{
    NSAssert(image != nil, @"imageToWebP:quality image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality quality has to be [0, 100]");
    
    return [self convertToWebP:image quality:quality alpha:1 preset:WEBP_PRESET_DEFAULT error:nil];
}

#pragma mark - Asynchronous methods
+ (void)imageFromWebP:(NSString *)filePath completionBlock:(void (^)(UIImage *result))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    NSAssert(filePath != nil, @"imageFromWebP:filePath:completionBlock:failureBlock filePath cannot be nil");
    NSAssert(completionBlock != nil, @"imageFromWebP:filePath:completionBlock:failureBlock completionBlock block cannot be nil");
    NSAssert(failureBlock != nil, @"imageFromWebP:filePath:completionBlock:failureBlock failureBlock block cannot be nil");
    
    // Create dispatch_queue_t for decoding WebP concurrently
    dispatch_queue_t fromWebPQueue = dispatch_queue_create("com.seanooi.ioswebp.fromwebp", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(fromWebPQueue, ^{
        
        NSError *error = nil;
        UIImage *webPImage = [self convertFromWebP:filePath error:&error];
        
        // Return results to caller on main thread in completion block is `webPImage` != nil
        // Else return in failure block
        if(webPImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(webPImage);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }
    });
}

+ (void)imageToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha preset:(WebPPreset)preset completionBlock:(void (^)(NSData *result))completionBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    NSAssert(image != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality:alpha:completionBlock:failureBlock quality has to be [0, 100]");
    NSAssert(alpha >= 0 && alpha <= 1, @"imageToWebP:quality:alpha:completionBlock:failureBlock alpha has to be [0, 1]");
    NSAssert(completionBlock != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock completionBlock cannot be nil");
    NSAssert(completionBlock != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock failureBlock block cannot be nil");
    
    // Create dispatch_queue_t for encoding WebP concurrently
    dispatch_queue_t toWebPQueue = dispatch_queue_create("com.seanooi.ioswebp.towebp", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(toWebPQueue, ^{
        
        NSError *error = nil;
        NSData *webPFinalData = [self convertToWebP:image quality:quality alpha:alpha preset:preset error:&error];
        
        // Return results to caller on main thread in completion block is `webPFinalData` != nil
        // Else return in failure block
        if(!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(webPFinalData);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
        }
    });
}

#pragma mark - Utilities

- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha
{
    NSAssert(alpha >= 0 && alpha <= 1, @"imageByApplyingAlpha:alpha alpha has to be [0, 1]");
    
    if (alpha < 1) {
        
       UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
       
       CGContextRef ctx = UIGraphicsGetCurrentContext();
       CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
       
       CGContextScaleCTM(ctx, 1, -1);
       CGContextTranslateCTM(ctx, 0, -area.size.height);
       
       CGContextSetAlpha(ctx, alpha);
       CGContextSetBlendMode(ctx, kCGBlendModeXOR);
       CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
       
       CGContextDrawImage(ctx, area, self.CGImage);
       
       UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
       
       UIGraphicsEndImageContext();
        
        return newImage;
         
    }
    else {
        return self;
    }
}

@end
