//
//  SASampleFileUtils.h
//  ConsumerPhysics
//
//  Created by Daniel David on 25/02/2016.
//  Copyright © 2016 ConsumerPhysics. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CPScioReading;

@interface SASampleFileUtils : NSObject

/*
 Stores object to file
 @param fileName
 @return a CPScioReading instance
 */
+ (BOOL)storeToDisk:(id)object fileName:(NSString *)fileName;

/*
 Reads from file
 @param fileName
 @return a CPScioReading instance or nil if doesn't exist
 */
+ (CPScioReading *)readArchiveWithFileName:(NSString *)fileName;

/*
 Removes from file
 @param fileName
 @return NSError. (nil on success)
 */
+ (NSError *)removeFromDiskFileName:(NSString *)fileName;

@end
