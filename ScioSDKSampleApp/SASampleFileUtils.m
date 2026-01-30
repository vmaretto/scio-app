//
//  SASampleFileUtils.m
//  ConsumerPhysics
//
//  Created by Daniel David on 25/02/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//

#import "SASampleFileUtils.h"
#import <ScioSDK/ScioSDK.h>

@implementation SASampleFileUtils

+ (BOOL)storeToDisk:(id)object fileName:(NSString *)fileName {
    NSLog(@"Store to disk. File name: %@", fileName);
    NSURL *folder = [SASampleFileUtils privateDocsStoreDirectory];
    NSURL *fileURL = [folder URLByAppendingPathComponent:fileName];
    
    NSError *error = [SASampleFileUtils archiveObject:object atURL:fileURL];
    if (error) {
        return NO;
    }
    return YES;
}

+ (CPScioReading *)readArchiveWithFileName:(NSString *)fileName {
    NSLog(@"Read archive from disk. File name: %@", fileName);
    NSURL *folder = [SASampleFileUtils privateDocsStoreDirectory];
    NSURL *fileURL = [folder URLByAppendingPathComponent:fileName];
    
    return [SASampleFileUtils readArchiveFromURL:fileURL];
}

+ (NSError *)removeFromDiskFileName:(NSString *)fileName {
    NSLog(@"Remove file from disk. File name: %@", fileName);
    NSURL *folder = [SASampleFileUtils privateDocsStoreDirectory];
    NSURL *fileURL = [folder URLByAppendingPathComponent:fileName];
    
    return [SASampleFileUtils removeItemAtURL:fileURL];
}

#pragma mark - Archived files utils -

+ (NSURL *)privateDocsStoreDirectory {
    static NSURL *ald = nil;
    
    if (ald == nil) {
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        NSURL *libraryURL = [fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        if (libraryURL == nil) {
            NSLog(@"Could not access Library directory\n%@", [error localizedDescription]);
        }
        else {
            ald = [libraryURL URLByAppendingPathComponent:@"PrivateDocs"];
            NSDictionary *properties = [ald resourceValuesForKeys:@[NSURLIsDirectoryKey]
                                                            error:&error];
            if (properties == nil) {
                if (![fileManager createDirectoryAtURL:ald withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"Could not create directory %@\n%@", [ald path], [error localizedDescription]);
                    ald = nil;
                }
            }
        }
    }
    return ald;
}

// URL utils
+ (id)readArchiveFromURL:(NSURL *)url {
    NSError *readError = nil;
    NSData *contents = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&readError];
    if (!contents) {
        return nil;
    }
    id deserializedData = [NSKeyedUnarchiver unarchiveObjectWithData:contents];
    if (deserializedData) {
        return deserializedData;
    }
    
    if (readError) {
        NSLog(@"readArchiveFromURL: error: %@", readError);
    }
    
    return nil;
}

+ (NSError *)archiveObject:(id)object atURL:(NSURL *)url {
    
    NSError *error;
    
    NSData *serializedData = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    BOOL success = [serializedData writeToURL:url options:NSDataWritingAtomic|NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    
    if (success) {
        NSDictionary *fileAttributes = @{ NSFileExtensionHidden: @YES };
        
        [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:url.path error:nil];
    }
    
    return error;
}

+ (NSError *)removeItemAtURL:(NSURL *)url {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSError *error;
    
    [fileManager removeItemAtURL:url error:&error];
    
    return error;
}

@end
