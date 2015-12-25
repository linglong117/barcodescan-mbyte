#import <Cordova/CDVPlugin.h>
#import <AVFoundation/AVFoundation.h>

#import "ZBarSDK.h"

//#import "CDVBCSViewController.h"

//@interface CDVBarcodeScanner : CDVPlugin
//
//
//@end

//------------------------------------------------------------------------------
// Delegate to handle orientation functions
//
//------------------------------------------------------------------------------
@protocol CDVBarcodeScannerOrientationDelegate <NSObject>

- (NSUInteger)supportedInterfaceOrientations;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (BOOL)shouldAutorotate;

@end


@class CDVBCSViewController;

@interface CDVXYLBarcodeScanner : CDVPlugin<UIImagePickerControllerDelegate,ZBarReaderDelegate> {
//@interface CDVXYLBarcodeScanner : CDVPlugin<UIImagePickerControllerDelegate> {

    int num;
    BOOL upOrdown;
    NSTimer * timer;
    
}

@property (nonatomic, strong) UIImageView * line;
@property (nonatomic,strong) NSString*       callback;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isReading;

- (NSString*)isScanNotPossible;
- (void)scan:(CDVInvokedUrlCommand*)command;
- (void)encode:(CDVInvokedUrlCommand*)command;
- (void)returnSuccess:(NSString*)scannedText format:(NSString*)format cancelled:(BOOL)cancelled flipped:(BOOL)flipped callback:(NSString*)callback;
- (void)returnError:(NSString*)message callback:(NSString*)callback;

@end

