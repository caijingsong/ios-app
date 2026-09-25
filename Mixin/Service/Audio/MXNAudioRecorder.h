#import <Foundation/Foundation.h>
#import "MXMAudioMetadata.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN const NSErrorDomain MXMAudioRecorderErrorDomain;

typedef NS_CLOSED_ENUM(NSUInteger, MXNAudioRecorderErrorCode) {
    MXNAudioRecorderErrorCodeAudioQueueNewInput,
    MXNAudioRecorderErrorCodeAudioQueueGetStreamDescription,
    MXNAudioRecorderErrorCodeAudioQueueAllocateBuffer,
    MXNAudioRecorderErrorCodeAudioQueueEnqueueBuffer,
    MXNAudioRecorderErrorCodeAudioQueueStart,
    MXNAudioRecorderErrorCodeAudioQueueGetMaximumOutputPacketSize,
    MXNAudioRecorderErrorCodeCreateAudioFile,
    MXNAudioRecorderErrorCodeWriteAudioFile,
    MXNAudioRecorderErrorCodeMediaServiceWereReset
};


@class MXMAudioRecorder;

@protocol MXMAudioRecorderDelegate <NSObject>

- (void)audioRecorderIsWaitingForActivation:(MXMAudioRecorder *)recorder NS_SWIFT_NAME(audioRecorderIsWaitingForActivation(_:));
- (void)audioRecorderDidStartRecording:(MXMAudioRecorder *)recorder;
- (void)audioRecorderDidCancelRecording:(MXMAudioRecorder *)recorder;
- (void)audioRecorder:(MXMAudioRecorder *)recorder didFailRecordingWithError:(NSError *)error;
- (void)audioRecorder:(MXMAudioRecorder *)recorder didFinishRecordingWithMetadata:(MXMAudioMetadata *)data NS_SWIFT_NAME(audioRecorder(_:didFinishRecordingWithMetadata:));

@end


@interface MXMAudioRecorder : NSObject

@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, assign, readwrite) BOOL vibratesAtBeginning;
@property (nonatomic, assign, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, weak, readwrite) id<MXMAudioRecorderDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithPath:(NSString *)path error:(NSError * _Nullable *)outError;
- (void)recordForDuration:(NSTimeInterval)duration NS_SWIFT_NAME(record(for:));
- (void)stop;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
