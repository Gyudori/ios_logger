//
//  theta_capture.m
//  ios_logger
//
//  Created by Ben on 2/23/24.
//  Copyright © 2024 Mac. All rights reserved.
//

#import "theta_capture.h"

@interface ThetaOSC ()
{
}
@end

@implementation ThetaOSC

static NSString *const BASE_URL = @"http://192.168.1.1/osc/%@";

- (instancetype)initWithSerial:(NSString *)serial verbose:(BOOL)verbose {
    self = [super init];
    if (self) {
        self.session = [NSURLSession sharedSession];
        self.serial = serial;
        self.verbose = verbose;
    }
    return self;
}

- (void)prepareDataAndHeadersWithURL:(NSString *)url data:(NSDictionary *)data headers:(NSMutableDictionary **)headers {
    if (data == nil) {
        return;
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        *headers = [@{@"Content-Type": @"application/json;charset=utf-8"} mutableCopy];
//        *headers = [@{@"Content-Type": @"application/json"} mutableCopy];
    } else {
        // Handle other data types as needed
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid data type" userInfo:nil];
    }

    if (*headers == nil) {
        *headers = [NSMutableDictionary dictionary];
    }

    [*headers setObject:@"application/json" forKey:@"Accept"];
}

- (NSDictionary *)sendRequestWithCommand:(NSString *)cmd data:(NSDictionary *)data headers:(NSMutableDictionary *)headers post:(BOOL)post {
    NSString *urlString = [NSString stringWithFormat:BASE_URL, cmd];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = post ? @"POST" : @"GET";
    
    if (data != nil){
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        // print jsonString
        printf("JSON String: %s\n", [jsonString UTF8String]);
    }

    [self prepareDataAndHeadersWithURL:urlString data:data headers:&headers];
    for (NSString *key in headers) {
        [request setValue:headers[key] forHTTPHeaderField:key];
    }
    
    if (self.verbose){
        // print values from properties of request instance
        printf("Sending...\n");
        printf("URL: %s\n", [[request.URL absoluteString] UTF8String]);
        printf("Method: %s\n", [request.HTTPMethod UTF8String]);
        printf("Headers: %s\n", [[request.allHTTPHeaderFields description] UTF8String]);
        // decode body to json string
        NSString *jsonString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        printf("Body: %s\n", [jsonString UTF8String]);
    }

    __block NSDictionary *responseDict = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // handle exception when data is nil
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error in %@ request: %@", post ? @"POST" : @"GET", error);
        } else {
            responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (self.verbose) {
                NSLog(@"Received %@ response: %@", post ? @"POST" : @"GET", responseDict);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];

    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return responseDict;
}

- (BOOL)setOptions:(NSDictionary *)options {
    @try {
        NSDictionary *response = [self sendRequestWithCommand:@"commands/execute" data:@{@"name": @"camera.setOptions", @"parameters": @{@"options": options}} headers:nil post:YES];
        return [response[@"state"] isEqualToString:@"done"];
    } @catch (NSException *exception) {
        return NO;
    }
}

- (NSDictionary *)getOptions:(id)options {
    if ([options isKindOfClass:[NSString class]]) {
        return [self sendRequestWithCommand:@"commands/execute" data:@{@"name": @"camera.getOptions", @"parameters": @{@"optionNames": options}} headers:nil post:YES][@"results"][@"options"];
    } else {
        // Handle other types as needed
        return nil;
    }
}

- (NSDictionary *)startSession {
    return [self sendRequestWithCommand:@"commands/execute" data:@{@"name": @"camera.startSession"} headers:nil post:YES];
}

- (NSDictionary *)info {
    return [self sendRequestWithCommand:@"info" data:nil headers:nil post:NO];
}

- (NSDictionary *)state {
    return [self sendRequestWithCommand:@"state" data:nil headers:nil post:YES];
}

- (NSDictionary *)statusWithId:(NSString *)commandId {
    return [self sendRequestWithCommand:@"commands/status" data:@{@"id": commandId} headers:nil post:YES];
}

- (BOOL)setCaptureMode:(NSString *)mode {
    return [self setOptions:@{@"captureMode": mode}];
}

- (NSDictionary *)getCaptureMode {
    return (NSDictionary *)[self getOptions:@"captureMode"];
}

- (NSDictionary *)getCaptureModeSupport {
    return (NSDictionary *)[self getOptions:@"captureModeSupport"];
}

- (NSDictionary *)getFileFormatSupport {
    return [self getOptions:@"fileFormatSupport"];
}

- (NSInteger)getExposureProgram {
    NSDictionary *options = [self getOptions:@"exposureProgram"];
    NSNumber *exposureProgramNumber = options[@"exposureProgram"];
    return [exposureProgramNumber integerValue];
}

- (BOOL)setExposureProgram:(NSInteger)exposureProgramId {
    return [self setOptions:@{@"exposureProgram": @(exposureProgramId)}];
}

- (NSArray<NSNumber *> *)getExposureProgramSupport {
    return (NSArray<NSNumber *> *)[self getOptions:@"exposureProgramSupport"];
}

- (NSArray<NSNumber *> *)getShutterSpeedSupport {
    return (NSArray<NSNumber *> *)[self getOptions:@"shutterSpeedSupport"];
}

- (BOOL)setShutterSpeed:(NSTimeInterval)timeSec {
    return [self setOptions:@{@"shutterSpeed": @(timeSec)}];
}

- (NSDictionary *)takePicture {
    return [self sendRequestWithCommand:@"commands/execute" data:@{@"name": @"camera.takePicture"} headers:nil post:YES];
}

- (NSDictionary *)startCapture {
    return [self sendRequestWithCommand:@"commands/execute" data:@{@"name": @"camera.startCapture"} headers:nil post:YES];
}

- (NSDictionary *)stopCapture {
    return [self sendRequestWithCommand:@"commands/execute" data:@{@"name": @"camera.stopCapture"} headers:nil post:YES];
}

- (void)setTimelapseVideoMode {
    NSLog(@"set_timelapse_video_mode");
    [self setCaptureMode:@"video"];
    [self setOptions:@{@"videoStitching": @"onboard"}];
    [self setOptions:@{@"_topBottomCorrection": @"Apply"}];
    NSLog(@"%@", [self getOptions:@"videoStitching"]);

    [self setOptions:@{@"fileFormat": @{@"_frameRate": @2, @"_bitRate": @8000000, @"_codec": @"H.264/MPEG-4 AVC", @"height": @2880, @"type": @"mp4", @"width": @5760}}];
}

- (void)setPictureMode {
    NSLog(@"set_picture_mode");
    [self setCaptureMode:@"image"];
    [self setOptions:@{@"_imageStitching": @"static"}];
    [self setOptions:@{@"_topBottomCorrection": @"Apply"}];
}

@end

void takePicture(ThetaOSC *theta) {
    [theta setPictureMode];
    NSString *commandId = [theta takePicture][@"id"];
    [NSThread sleepForTimeInterval:3];
    [theta statusWithId:commandId];
}

void takeTimelapseVideo(ThetaOSC *theta) {
    [theta setTimelapseVideoMode];
    [theta startCapture];
    [NSThread sleepForTimeInterval:10];
    NSDictionary *res = [theta stopCapture];
    NSLog(@"%@", res);
}

//int main(int argc, const char * argv[]) {
//    @autoreleasepool {
//        // Command line arguments handling
//        NSString *serialNumber = @"YN12100631"; // Set your serial number
//        ThetaOSC *theta = [[ThetaOSC alloc] initWithSerial:serialNumber verbose:YES];
//
//        NSLog(@"Theta initialized");
//        [theta info];
//        NSLog(@"Theta info updated");
//        [theta state];
//        NSLog(@"Theta state updated");
//        [theta startSession];
//
//        // Uncomment and modify the following lines based on your requirements
//        // [theta setExposureProgram:1];
//        // [theta setShutterSpeed:0.001125];
//        // [theta setExposureProgram:2];
//
//        takeTimelapseVideo(theta);
//    }
//    return 0;
//}
