#iOS-WebP

Most apps nowadays enhance user experience with the use of images, and one of the issues I've noticed with that is the amount of time it takes to load an image. (_Not everyone has the luxury of a fast connection_)

Google's WebP image format offers better compression compared to PNG or JPEG, allowing apps to send/retrieve images with smaller file sizes, reducing request times and hopefully provide a better user experience.

![alt demo](http://i.imgur.com/V4fBG1h.png "Demo Screenshot")

#Getting Started

###The CocoaPods Way
```ruby
pod 'iOS-WebP', '0.2'
```

###The Manual Way
Include the 3 files inside the `iOS-WebP` folder into your project:
* `UIImage+WebP.h`
* `UIImage+WebP.m`
* `WebP.framework`

#Usage
Don't forget to `#import "UIImage+WebP.h"` or `#import <UIImage+WebP.h>` if you're using cocoapods.
There are 3 methods in `iOS-WebP`, converting images __to__ WebP format, converting images __from__ WebP format, and setting an image's transparency.
```objc
+ (void)imageFromWebP:(NSString *)filePath completionBlock:(void (^)(UIImage *result))completionBlock failureBlock:(void (^)(NSString *error))failureBlock;

+ (void)imageToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha completionBlock:(void (^)(NSData *result))completionBlock failureBlock:(void (^)(NSString *error))failureBlock;

- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;
```

Encoding and decoding of images are done in the background thread and results returned in the completion block on the main thread so as not to lock the main thread, allowing the UI to be updated as needed.

#### Converting To WebP

```objc
// quality value is [0, 100]
// alpha value is [0, 1]
[UIImage imageToWebP:demoImage quality:75 alpha:0.5 completionBlock:^(NSData *result) {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *webPPath = [paths[0] stringByAppendingPathComponent:@"image.webp"];
  if (![webPData writeToFile:webPPath atomically:YES]) {
    NSLog(@"Failed to save file");
  }
} failureBlock:^(NSString *error) {
  NSLog(@"%@", error);
}];
```

#### Converting From WebP

```objc
[UIImage imageFromWebP:@"/path/to/file" completionBlock:^(UIImage *result) {
  UIImageView *myImageView = [[UIImageView alloc] initWithImage:result];
}failureBlock:^(NSString *error) {
  NSLog(@"%@", error);
}];
```

#### Setting Image Transparency

```objc
//alpha value is [0, 1]
UIImage *transparencyImage = [[UIImage imageNamed:image.jpg] imageByApplyingAlpha:0.5];
```

Credit
========
* Based off [WebP-iOS-example](https://github.com/carsonmcdonald/WebP-iOS-example "WebP-iOS-example") by Carson McDonald
* Image transparency function contributed by [shmidt](https://github.com/shmidt)
