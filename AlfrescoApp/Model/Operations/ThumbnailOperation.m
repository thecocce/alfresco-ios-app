/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import "ThumbnailOperation.h"

@interface ThumbnailOperation ()
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) NSString *rendition;
@property (nonatomic, copy) AlfrescoContentFileCompletionBlock contentFileCompletionBlock;
@end

@implementation ThumbnailOperation
{
    BOOL _complete;
    BOOL _stopRunLoop;
    NSThread *_myThread;
}

- (id)initWithDocumentFolderService:(AlfrescoDocumentFolderService *)service document:(AlfrescoDocument *)document renditionName:(NSString *)rendition completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    self = [super init];
    if (self)
    {
        self.documentFolderService = service;
        self.document = document;
        self.rendition = rendition;
        self.contentFileCompletionBlock = completionBlock;
        self.minimumDelayBetweenRequests = 0;
    }
    return self;
}

- (void)rateLimitMonitor:(NSTimer *)timer
{
    [timer invalidate];
}

- (void)main
{
    _myThread = [NSThread currentThread];
    
    NSTimer *myTimer = [NSTimer timerWithTimeInterval:self.minimumDelayBetweenRequests target:self selector:@selector(rateLimitMonitor:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
    
    [self.documentFolderService retrieveRenditionOfNode:self.document renditionName:self.rendition completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
        if (self.contentFileCompletionBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.contentFileCompletionBlock(contentFile, error);
            });
        }
    }];
    
    while ((!_stopRunLoop || [myTimer isValid]) && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    _complete = YES;
}

- (void)internalComplete
{
    _stopRunLoop = YES;
}

- (void)setComplete
{
    [self performSelector:@selector(internalComplete) onThread:_myThread withObject:nil waitUntilDone:NO];
}

- (BOOL)isFinished
{
    return _complete;
}

@end
