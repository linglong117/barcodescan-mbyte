
//
//  CDVBCSViewController.m
//
//  CDVBarcodeScanViewController
//
//  Created by xyl on 2015-12-11 21:07:07.
//  Copyright (c) 2015年 . All rights reserved.
//

#import "CDVBCSViewController.h"


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




#define RETICLE_SIZE    500.0f
#define RETICLE_WIDTH    1.0f
#define RETICLE_WIDTH_REDLINE    2.0f
#define RETICLE_OFFSET   60.0f
#define RETICLE_ALPHA     0.5f
#define kLine_Width 4.0f
#define kLine_Length 80.0f

#define kReticleX  37*2
//#define kReticle
#define kQRWidth 15
#define kORHeight 15


@interface CDVBCSViewController ()

@end

@implementation CDVBCSViewController

@synthesize plugin=_plugin;
@synthesize session=_session;
@synthesize isReading=_isReading;
@synthesize orientationDelegate=_orientationDelegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    [self initView];
    //
    [self loadBeepSound];

}


/*
 * init  label  toolbar
 */
- (void) initView
{
    CGRect bounds = self.view.bounds;
    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);

    
    UIButton * scanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [scanButton setTitle:@"取消" forState:UIControlStateNormal];
    scanButton.frame = CGRectMake(100, 420, 120, 40);
    [scanButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    // [self.view addSubview:scanButton];
    
    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(0, 60, bounds.size.width, 60)];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.numberOfLines=2;
    UIFont *baseFont = [UIFont systemFontOfSize:13];
    //labIntroudction.font = [UIFont fontWithName:@"" size:13];
    labIntroudction.font = baseFont;
    labIntroudction.numberOfLines=0;
    labIntroudction.textAlignment = MBLabelAlignmentCenter;
    //自动换行设置
    labIntroudction.lineBreakMode = LINE_BREAK_WORD_WRAP;
    labIntroudction.textColor=[UIColor whiteColor];
    //labIntroudction.text=@"将二维码图像置于矩形方框内，离手机摄像头10CM左右，系统会自动识别";
    labIntroudction.text=@"二维码离手机摄像头10CM左右，系统会自动识别";

    [self.view addSubview:labIntroudction];

    //扫描框图片
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 100, 300, 300)];
    imageView.image = [UIImage imageNamed:@"pick_bg"];
    //[self.view addSubview:imageView];
    
    //激光线
    upOrdown = NO;
    num =0;
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(50, 110, 220, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    //[self.view addSubview:_line];
    //timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];

    
    //add toolbar
//    CGRect bounds = self.view.bounds;
//    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    UIView* overlayView = [[UIView alloc] initWithFrame:bounds] ;
    overlayView.autoresizesSubviews = YES;
    overlayView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.opaque              = NO;
    
    UIToolbar* toolbar = [[UIToolbar alloc] init] ;
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    id cancelButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                       target:(id)self
                       action:@selector(cancelButtonPressed:)
                       ];
    
    //    id cancelButton = [[[UIBarButtonItem alloc] autorelease]
    //                       initWithTitle:@"取消" style:UIBarButtonItemStylePlain
    //                       target:(id)self
    //                       action:@selector(cancelButtonPressed:)
    //                       ];
    
    id flexSpace = [[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                    target:nil
                    action:nil
                    ];
    //    id flipCamera = [[[UIBarButtonItem alloc] autorelease]
    //                       initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
    //                       target:(id)self
    //                       action:@selector(flipCameraButtonPressed:)
    //                       ];
    
    
#if USE_SHUTTER
    id shutterButton = [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                        target:(id)self
                        action:@selector(shutterButtonPressed)
                        ];
    
    //toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace, flipCamera ,shutterButton,nil];
    toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace ,shutterButton,nil];
#else
    //toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace, flipCamera,nil];
    toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace,nil];
    
#endif
    bounds = overlayView.bounds;
    
    [toolbar sizeToFit];
    CGFloat toolbarHeight  = [toolbar frame].size.height;
    CGFloat rootViewHeight = CGRectGetHeight(bounds);
    CGFloat rootViewWidth  = CGRectGetWidth(bounds);
    CGRect  rectArea       = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
    [toolbar setFrame:rectArea];
    
    [overlayView addSubview: toolbar];
    [self.view addSubview:overlayView];
    
    _isReading = NO;
    //self.plugin =
    //[_lightButton setTitle:@"打开照明" forState:UIControlStateNormal];
}


//激光线动画
-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(50, 110+2*num, 220, 2);
        if (2*num == 280) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(50, 110+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }

}

//
- (void)cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
        
        [self barcodeScanDone];
        [self.plugin returnSuccess:@"" format:@"" cancelled:TRUE flipped:false callback:self.callback];
    }];
}

-(void)backAction
{
    [self dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self setupCamera];
}

- (void)setupCamera
{
    // 初始化输入流
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
     // 添加输入流
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
     // 初始化输出流
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 创建会话
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    
    // 设置元数据类型 AVMetadataObjectTypeQRCode
    //[_output setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // 创建输出对象
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //_preview.frame =CGRectMake(20,110,280,280);
    _preview.frame = self.view.bounds;
    //[self.view.layer insertSublayer:self.preview atIndex:0];
    [self.view.layer insertSublayer:_preview below:[[self.view.layer sublayers] objectAtIndex:0]];
    
    //[self.view addSubview:[self buildOverlayView]];
    
    // Start
    [_session startRunning];
}

/*
 *
 * load beep audio
 */
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

- (IBAction)openSystemLight:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if ([button.titleLabel.text isEqualToString:@"打开照明"]) {
        [self systemLightSwitch:YES];
    } else {
        [self systemLightSwitch:NO];
    }
}

- (void)systemLightSwitch:(BOOL)open
{
    if (open) {
        //[_lightButton setTitle:@"关闭照明" forState:UIControlStateNormal];
    } else {
        //[_lightButton setTitle:@"打开照明" forState:UIControlStateNormal];
    }
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (open) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}


#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
   
    NSString *stringValue;
    NSString *formatVal;
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.

            stringValue = metadataObj.stringValue;
            formatVal = metadataObj.type;
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            //[_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
            _isReading = NO;
            // If the audio player is not nil, then play the sound effect.
            if (_audioPlayer) {
                [_audioPlayer play];
            }
        }else
        {
            NSLog(@"未能识别");
            [self barcodeScanFailed:@"未能识别"];
        }
    }else
    {
        NSLog(@"未能识别");
        [self barcodeScanFailed:@"未能识别"];
    }
    
   [self dismissViewControllerAnimated:YES completion:^
    {
        [timer invalidate];
         NSLog(@"找到纯文本-> %@",stringValue);
        [self barcodeScanSucceeded:stringValue format:formatVal];
    }];
}

-(void)stopReading{
    // Stop video capture and make the capture session object nil.
    [_session stopRunning];
    _session = nil;
    // Remove the video preview layer from the viewPreview view's layer.
    [_preview removeFromSuperlayer];
    
    [self dismissViewControllerAnimated:YES completion:^{
        //SHOW YOUR NEW VIEW CONTROLLER HERE!
    }];
    
    //[self dismissViewControllerAnimated:YES completion:nil];

}

//--------------------------------------------------------------------------
- (void)barcodeScanSucceeded:(NSString*)text format:(NSString*)format {
   // [self barcodeScanDone];
    [self.plugin returnSuccess:text format:format cancelled:FALSE flipped:FALSE callback:self.callback];
}

//--------------------------------------------------------------------------
- (void)barcodeScanFailed:(NSString*)message {
    //[self barcodeScanDone];
    [self stopReading];
    [self.plugin returnError:message callback:self.callback];
}

//--------------------------------------------------------------------------
- (void)barcodeScanCancelled {
    [self barcodeScanDone];
//    [self.plugin returnSuccess:@"" format:@"" cancelled:TRUE flipped:self.isFlipped callback:self.callback];
//    if (self.isFlipped) {
//        self.isFlipped = NO;
//    }
}


//--------------------------------------------------------------------------
- (void)barcodeScanDone {
    self.isReading = NO;
    [_session stopRunning];
    _session =nil;
    //[self.parentViewController dismissModalViewControllerAnimated: YES];
    //[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    // viewcontroller holding onto a reference to us, release them so they
    // will release us
    //self.viewController = nil;
    // delayed [self release];
    //[self performSelector:@selector(release) withObject:nil afterDelay:1];
}


#pragma mark CDVBarcodeScannerOrientationDelegate

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    [CATransaction begin];
    
    //_preview.orientation = orientation;
   
    [_preview layoutSublayers];
    _preview.frame = self.view.bounds;
    
    [CATransaction commit];
    [super willAnimateRotationToInterfaceOrientation:orientation duration:duration];
}


- (void)dealloc
{
    [self stopReading];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
