#import "CDVXYLBarcodeScanner.h"
#import <Cordova/CDVPluginResult.h>
#import "CDVBCSViewController.h"
#import <Cordova/CDVViewController.h>

//#import "ZBarSDK.h"


#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#define MBLabelAlignmentCenter NSTextAlignmentCenter
#define MBLabelAlignmentLeft   NSTextAlignmentLeft
#define MBLabelAlignmentRight   NSTextAlignmentRight
#else
#define MBLabelAlignmentCenter UITextAlignmentCenter
#define MBLabelAlignmentLeft UITextAlignmentLeft
#define MBLabelAlignmentRight   UITextAlignmentRight

#endif

//by xyl 2013-11-27 16:04:09
#if __IPHONE_6_0 >=60000
# define LINE_BREAK_WORD_WRAP NSLineBreakByWordWrapping
#else
# define LINE_BREAK_WORD_WRAP UILineBreakModeWordWrap
#endif

#if __IPHONE_6_0 >=60000
# define LINE_BREAK_BY_TAIL NSLineBreakByTruncatingTail
#else
# define LINE_BREAK_BY_TAIL UILineBreakModeTailTruncation
#endif


#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define MB_TEXTSIZE(text, font) [text length] > 0 ? [text \
sizeWithAttributes:@{NSFontAttributeName:font}] : CGSizeZero;
#else
#define MB_TEXTSIZE(text, font) [text length] > 0 ? [text sizeWithFont:font] : CGSizeZero;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define MB_MULTILINE_TEXTSIZE(text, font, maxSize, mode) [text length] > 0 ? [text \
boundingRectWithSize:maxSize options:(NSStringDrawingUsesLineFragmentOrigin) \
attributes:@{NSFontAttributeName:font} context:nil].size : CGSizeZero;
#else
#define MB_MULTILINE_TEXTSIZE(text, font, maxSize, mode) [text length] > 0 ? [text \
sizeWithFont:font constrainedToSize:maxSize lineBreakMode:mode] : CGSizeZero;
#endif


#define IOS7 [[[UIDevice currentDevice] systemVersion]floatValue]>=7


@implementation NSBundle (PluginExtensions)

+ (NSBundle*) pluginBundle:(CDVPlugin*)plugin {
    NSBundle* bundle = [NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:NSStringFromClass([plugin class]) ofType: @"bundle"]];
    return bundle;
}
@end

#define PluginLocalizedString(plugin, key, comment) [[NSBundle pluginBundle:(plugin)] localizedStringForKey:(key) value:nil table:nil]



@implementation CDVXYLBarcodeScanner

NSString *ipaPath;
NSString *_chineshWordPath;
NSString *_englishWordPath;
NSMutableDictionary *dict;
NSString *title;

@synthesize callback=_callback;
@synthesize isReading;
@synthesize audioPlayer=_audioPlayer;


CDVXYLBarcodeScanner *cmdBarcode;

//AVAudioPlayer *player;

//--------------------------------------------------------------------------
- (NSString*)isScanNotPossible {
    NSString* result = nil;
    
    Class aClass = NSClassFromString(@"AVCaptureSession");
    if (aClass == nil) {
        return @"AVFoundation Framework not available";
    }
    
    return result;
}


- (void)requestCameraPermissionWithSuccess:(void (^)(BOOL success))successBlock {
    if (![self cameraIsPresent]) {
        successBlock(NO);
        return;
    }
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
        successBlock(YES);
        break;
        
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        successBlock(NO);
        break;
        
        case AVAuthorizationStatusNotDetermined:
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         successBlock(granted);
                                     });
                                     
                                 }];
        break;
    }
}

- (BOOL)scanningIsProhibited {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        return YES;
        break;
        
        default:
        return NO;
        break;
    }
}

- (BOOL)cameraIsPresent {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}
- (void)displayPermissionMissingAlert {
    NSString *message = nil;
    if ([self scanningIsProhibited]) {
        message = @"请在“设置－隐私－相机”选项中，允许本APP访问您的相机";
    } else if (![self cameraIsPresent]) {
        message = @"没有相机";
    } else {
        message = @"发生一个未知错误";
    }
    
    [[[UIAlertView alloc] initWithTitle:@""
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"确认"
                      otherButtonTitles:nil] show];
}


//--------------------------------------------------------------------------
- (void)scan:(CDVInvokedUrlCommand*)command {
    
   // NSString*       callback;
    //NSString *       capabilityError;
    self.callback = command.callbackId;
    NSLog(@"command  >>  %@ ",command);
    
    //[self scanBtnAction];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];


    [self requestCameraPermissionWithSuccess:^(BOOL success) {
        
        NSString*       capabilityError;
        capabilityError = [self isScanNotPossible];
        
        if (capabilityError) {
            [self returnError:capabilityError callback:self.callback];
            return;
        }
        
        if (success) {
            if(IOS7)
            {
                CDVBCSViewController * cdvBCSVC = [[CDVBCSViewController alloc] init];
                cdvBCSVC.callback = self.callback;
                cdvBCSVC.plugin = self;
                cdvBCSVC.orientationDelegate = self;
                [self.viewController presentViewController:cdvBCSVC animated:YES completion:^{
                    
                }];
            }
            else
            {
                [self scanBtnAction];
            }

        }else
        {
            [self displayPermissionMissingAlert];
            [self returnError:@"调用相机错误" callback:command.callbackId];

        }
    }];
    
   }

-(void)scanBtnAction
{
    CGRect bounds = self.viewController.view.bounds;
    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);

    
    num = 0;
    upOrdown = NO;
    //初始话ZBar
    ZBarReaderViewController * reader = [ZBarReaderViewController new];
    
    //NSLog(@" subview -> %@",[reader.view subviews]);
    //reader.view.backgroundColor = [UIColor lightGrayColor];
    
    for (UIView *temp in [reader.view subviews]) {
        for (UIView *view2 in [temp subviews]) {
            if ([view2 isKindOfClass:[UIToolbar class]]) {
                for (UIView *view3 in [view2 subviews]) {
                    if ([view3 isKindOfClass:[UIButton class]]) {
                        [view3 removeFromSuperview];
                    }
                }
            }
        }
    }
    
    //设置代理
    reader.readerDelegate = self;
    //支持界面旋转
    reader.supportedOrientationsMask = ZBarOrientationMaskAll;
    reader.showsHelpOnFail = NO;
    reader.scanCrop = CGRectMake(0.1, 0.2, 0.8, 0.8);//扫描的感应框
    ZBarImageScanner * scanner = reader.scanner;
    [scanner setSymbology:ZBAR_I25
                   config:ZBAR_CFG_ENABLE
                       to:0];
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
    view.backgroundColor = [UIColor clearColor];
    reader.cameraOverlayView = view;
    
    
//    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 280, 40)];
//    label.text = @"请将扫描的二维码至于下面的框内\n谢谢！";
//    label.textColor = [UIColor whiteColor];
//    label.textAlignment = 1;
//    label.lineBreakMode = 0;
//    label.numberOfLines = 2;
//    label.backgroundColor = [UIColor clearColor];
//    [view addSubview:label];
    
    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(0, 50, bounds.size.width, 60)];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.numberOfLines=2;
    UIFont *baseFont = [UIFont systemFontOfSize:14];
    //labIntroudction.font = [UIFont fontWithName:@"" size:13];
    labIntroudction.font = baseFont;
    labIntroudction.numberOfLines=0;
    labIntroudction.textAlignment = MBLabelAlignmentCenter;
    //自动换行设置
    labIntroudction.lineBreakMode = LINE_BREAK_WORD_WRAP;
    labIntroudction.textColor=[UIColor whiteColor];
    //labIntroudction.text=@"将二维码图像置于矩形方框内，离手机摄像头10CM左右，系统会自动识别";
    labIntroudction.text=@"二维码离手机摄像头10CM左右，系统会自动识别";
    
    [view addSubview:labIntroudction];
    
    UIImageView * image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pick_bg.png"]];
    image.frame = CGRectMake(20, 80, 280, 280);
    //[view addSubview:image];
    
    
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(30, 10, 220, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    [image addSubview:_line];
    //定时器，设定时间过1.5秒，
    //timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
    
    [self loadBeepSound];
    
    [self.viewController presentViewController:reader animated:YES completion:^{
        
    }];
}

-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(30, 10+2*num, 220, 2);
        if (2*num == 260) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(30, 10+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [timer invalidate];
    _line.frame = CGRectMake(30, 10, 220, 2);
    num = 0;
    upOrdown = NO;
    [picker dismissViewControllerAnimated:YES completion:^{
        [picker removeFromParentViewController];
    }];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    
    if (_audioPlayer) {
        [_audioPlayer play];
    }
    
    [timer invalidate];
    _line.frame = CGRectMake(30, 10, 220, 2);
    num = 0;
    upOrdown = NO;
    [picker dismissViewControllerAnimated:YES completion:^{
        [picker removeFromParentViewController];
        UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
        //初始化
        ZBarReaderController * read = [ZBarReaderController new];
        //设置代理
        read.readerDelegate = self;
        CGImageRef cgImageRef = image.CGImage;
        ZBarSymbol * symbol = nil;
        id <NSFastEnumeration> results = [read scanImage:cgImageRef];
        for (symbol in results)
        {
            break;
        }
        NSString * result;
        if ([symbol.data canBeConvertedToEncoding:NSShiftJISStringEncoding])
        {
            result = [NSString stringWithCString:[symbol.data cStringUsingEncoding: NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
        }
        else
        {
            result = symbol.data;
        }
      
        [self returnSuccess:result format:@"" cancelled:false flipped:false callback:self.callback];
        NSLog(@"%@",result);
        
    }];
}

-(void)loadBeepSound{
    // Get the path to the beep.mp3 file and convert it to a NSURL object.
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"caf"];
    NSURL *beepURL=[[NSURL alloc] initFileURLWithPath:beepFilePath];
    
    NSError *error;
    
    // Initialize the audio player object using the NSURL object previously set.
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error) {
        // If the audio player cannot be initialized then log a message.
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    }
    else{
        // If the audio player was successfully initialized then load it in memory.
        [_audioPlayer prepareToPlay];
    }
}


//--------------------------------------------------------------------------
- (void)encode:(CDVInvokedUrlCommand*)command {
    [self returnError:@"encode function not supported" callback:command.callbackId];
}

//--------------------------------------------------------------------------
- (void)returnSuccess:(NSString*)scannedText format:(NSString*)format cancelled:(BOOL)cancelled flipped:(BOOL)flipped callback:(NSString*)callback{
    
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];

    
    NSNumber* cancelledNumber = [NSNumber numberWithInt:(cancelled?1:0)];
    
    NSMutableDictionary* resultDict = [[NSMutableDictionary alloc] init] ;
    [resultDict setObject:scannedText     forKey:@"text"];
    [resultDict setObject:format          forKey:@"format"];
    [resultDict setObject:cancelledNumber forKey:@"cancelled"];
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsDictionary: resultDict
                               ];
    
//    NSString* js = [result toSuccessCallbackString:callback];
//    if (!flipped) {
//        [self writeJavascript:js];
//    }
    [self.commandDelegate sendPluginResult:result callbackId:callback];

}

//--------------------------------------------------------------------------
- (void)returnError:(NSString*)message callback:(NSString*)callback {
    
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];

//    CDVPluginResult* result = [CDVPluginResult
//                               resultWithStatus: CDVCommandStatus_OK
//                               messageAsString: message
//                               ];

    NSMutableDictionary* resultDict = [[NSMutableDictionary alloc] init] ;
    [resultDict setObject:message     forKey:@"text"];
    //[resultDict setObject:format          forKey:@"format"];
    //[resultDict setObject:cancelledNumber forKey:@"cancelled"];
    [resultDict setObject:@"-1"     forKey:@"unidentifiedKFlag"];

    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsDictionary: resultDict
                               ];
    
//    NSString* js = [result toErrorCallbackString:callback];
//    [self writeJavascript:js];
    [self.commandDelegate sendPluginResult:result callbackId:callback];

}




- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 10000) {
        if (buttonIndex == 1) {
            NSURL *url = [NSURL URLWithString:ipaPath];
            [[UIApplication sharedApplication]openURL:url];
        }
    }
}


@end