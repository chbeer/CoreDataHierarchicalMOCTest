//
//  Person.h
//  CoreDataHierarchicalMOCTest
//
//  Created by Christian Beer on 24.04.13.
//  Copyright (c) 2013 Christian Beer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;

@end
