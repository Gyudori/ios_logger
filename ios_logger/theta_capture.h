//
//  Header.h
//  ios_logger
//
//  Created by Ben on 2/23/24.
//  Copyright © 2024 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThetaOSC : NSObject

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSString *serial;
@property (nonatomic) BOOL verbose;

- (instancetype)initWithSerial:(NSString *)serial verbose:(BOOL)verbose;
- (void)prepareDataAndHeadersWithURL:(NSString *)url data:(NSDictionary *)data headers:(NSMutableDictionary **)headers;
- (NSDictionary *)sendRequestWithCommand:(NSString *)cmd data:(NSDictionary *)data headers:(NSMutableDictionary *)headers post:(BOOL)post;
- (BOOL)setOptions:(NSDictionary *)options;
- (NSDictionary *)getOptions:(id)options;
- (NSDictionary *)startSession;
- (NSDictionary *)info;
- (NSDictionary *)state;
- (NSDictionary *)statusWithId:(NSString *)commandId;
- (BOOL)setCaptureMode:(NSString *)mode;
- (NSString *)getCaptureMode;
- (NSString *)getCaptureModeSupport;
- (NSDictionary *)getFileFormatSupport;
- (NSInteger)getExposureProgram;
- (BOOL)setExposureProgram:(NSInteger)exposureProgramId;
- (NSArray<NSNumber *> *)getExposureProgramSupport;
- (NSArray<NSNumber *> *)getShutterSpeedSupport;
- (BOOL)setShutterSpeed:(NSTimeInterval)timeSec;
- (NSDictionary *)takePicture;
- (NSDictionary *)startCapture;
- (NSDictionary *)stopCapture;
- (void)setTimelapseVideoMode;
- (void)setPictureMode;

@end

