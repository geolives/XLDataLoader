//
//  PostRemoteDataLoader.m
//  XLTableViewControllerTest
//
//  Created by Gaston Borba on 4/15/14.
//  Copyright (c) 2014 XmartLabs. All rights reserved.
//

#import "PostRemoteDataLoader.h"
#import "Post+Additions.h"
#import "AppDelegate+Additions.h"
#import "HTTPSessionManager.h"

#import "NSError+Additions.h"
#import "NSObject+Additions.h"

#define POST_TAG @"post"

@implementation PostRemoteDataLoader

#pragma mark - XLRemoteDataLoader overrides

-(AFHTTPSessionManager *)sessionManager
{
    return [HTTPSessionManager sharedClient];
}

-(NSString *)URLString
{
    return @"/mobile/posts.json";
}

-(NSDictionary *)parameters
{
    return @{@"offset": @(self.offset),
             @"limit": @(self.limit)};
}

-(void)successulDataLoad {
    // [self fetchedData] contains the data coming from the server
    NSArray * itemsArray = [[self fetchedData] objectForKey:kXLRemoteDataLoaderDefaultKeyForNonDictionaryResponse];
    // This flag indicates if there is more data to load
    _hasMoreToLoad = !((itemsArray.count == 0) || (itemsArray.count < _limit && itemsArray.count != 0));
    
    [[AppDelegate managedObjectContext] performBlockAndWait:^{
        for (NSDictionary *item in itemsArray) {
            // Creates or updates the Post and the user who created it with the data that came from the server
            [Post createOrUpdateWithServiceResult:item[POST_TAG] saveContext:NO];
        }
        
        // Remove outdated data
        [self removeOutdatedData:itemsArray];
        
        [AppDelegate saveContext];
    }];
    
    // call super
    [super successulDataLoad];
}


#pragma mark - Auxiliary Functions

- (void)removeOutdatedData:(NSArray *)data
{
    // First, remove older data
    NSFetchRequest * fetchRequest = [Post getFetchRequest];
    fetchRequest.fetchLimit = self.limit;
    fetchRequest.fetchOffset = self.offset;
    
    NSError *error;
    NSArray * oldObjects = [[AppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    NSArray * arrayToIterate = [oldObjects copy];
    
    if (error) {
        [error showAlertView];
        return;
    }
    
    for (Post *post in arrayToIterate)
    {
        NSArray *filteredArray = [data filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"post.id = %@" argumentArray:@[post.postId]]];
       if (filteredArray.count == 0) {
            // This Post no longer exists
            [[AppDelegate managedObjectContext] deleteObject:post];
        }
    }
}

@end
