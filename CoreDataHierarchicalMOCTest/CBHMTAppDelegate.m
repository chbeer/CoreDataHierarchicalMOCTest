//
//  CBHMTAppDelegate.m
//  CoreDataHierarchicalMOCTest
//
//  Created by Christian Beer on 24.04.13.
//  Copyright (c) 2013 Christian Beer. All rights reserved.
//

#import "CBHMTAppDelegate.h"

#import "Person.h"


@interface CBHMTAppDelegate ()

@property (nonatomic, retain, readwrite) NSManagedObjectModel           *managedObjectModel;
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator   *persistentStoreCoordinator;
@property (nonatomic, retain, readwrite) NSManagedObjectContext         *managedObjectContext;

@property (nonatomic, retain, readwrite) NSManagedObjectContext         *rootManagedObjectContext;

@end


@implementation CBHMTAppDelegate

#pragma mark - Core Data Stack

- (BOOL) flushUnsavedChanges:(NSError*__autoreleasing*)error
{
    if (!_managedObjectContext) return NO;
    
    __block BOOL result = YES;
    __block NSError *outError;
    
    [_managedObjectContext performBlockAndWait:^{
        NSLog(@"2a >> has changes: %@", [_managedObjectContext insertedObjects]);
        if ([_managedObjectContext hasChanges]) {
            NSError *error;
            BOOL success = [_managedObjectContext save:&error];
            if (!success) {
                NSLog(@"[fatal] could not save main managedObjectContext: %@", error);
                result = NO;
                outError = error;
                return;
            }
            
            NSLog(@"2b >> has changes: %@", [_rootManagedObjectContext insertedObjects]);
            [_rootManagedObjectContext performBlockAndWait:^{
                NSError *error = nil;
                BOOL success = [_rootManagedObjectContext save:&error];
                if (!success) {
                    NSLog(@"[fatal] could not save root managedObjectContext: %@", error);
                    result = NO;
                    outError = error;
                    return;
                }
            }];
        }
    }];

    if (error) *error = outError;
    
    return result;
}

- (NSManagedObjectContext *) managedObjectContext
{
    NSAssert([NSThread isMainThread], @"ManagedObject context can only be accessed on main thread!");
    
    return [self managedObjectContextInternal];
}
- (NSManagedObjectContext *) managedObjectContextInternal
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator == nil) return nil;
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.parentContext = [self rootManagedObjectContext];
    
#ifdef TARGET_OS_IPHONE
    //Undo Support
    NSUndoManager *undoManager = [[NSUndoManager alloc] init];
    [_managedObjectContext setUndoManager:undoManager];
#endif
    
    return _managedObjectContext;
}

- (NSManagedObjectContext *) rootManagedObjectContext
{
    if (_rootManagedObjectContext) return _rootManagedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator == nil) return nil;
    
    _rootManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_rootManagedObjectContext setPersistentStoreCoordinator:coordinator];
    
    _rootManagedObjectContext.undoManager = nil;
    
    return _rootManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TestModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self class] applicationDatabaseFileURL];
    
    NSError *error = nil;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSManagedObjectModel *model = [self managedObjectModel];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                                                         options:options error:&error]) {
        NSLog(@"Unresolved error %@ -> %@", [error localizedDescription], [[error userInfo] valueForKey:@"NSUnderlyingError"]);
        NSLog(@"  - source: %@ - target: %@", [error valueForKeyPath:@"userInfo.sourceModel.versionIdentifiers"], [error valueForKeyPath:@"userInfo.destinationModel.versionIdentifiers"]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

+ (NSURL*)applicationDatabaseFileURL
{
    return [[self applicationDatabaseDirectoryURL] URLByAppendingPathComponent:@"Test.sqlite"];
}
+ (NSURL*)applicationDatabaseDirectoryURL
{
    NSURL *applicationSupportFolderURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                                 inDomains:NSUserDomainMask] objectAtIndex:0];
    NSURL *applicationFolderURL = [applicationSupportFolderURL URLByAppendingPathComponent:@"Test"];
    
	NSURL *url = [applicationFolderURL URLByAppendingPathComponent:@"Database"];
    
    BOOL dir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&dir]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES
                                                       attributes:nil error:&error]) {
            NSAssert(NO, @"Could not create database directory: %@", url);
        }
    }
    return url;
}

#pragma mark - Actions

- (IBAction)test:(id)sender {
    NSLog(@"using database: %@", [[[self class] applicationDatabaseFileURL] path]);

    BOOL success = NO;
    NSError *error = nil;

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person"
                                              inManagedObjectContext:self.managedObjectContext];
    
    // create temporary person (this is my use case in my app)
    Person *person = (Person *)[[NSManagedObject alloc] initWithEntity:entity
                                        insertIntoManagedObjectContext:nil];
    
    person.firstName = @"Bunny";
    person.lastName  = @"Lebowski";
    
    [self.managedObjectContext insertObject:person];
    success = [self.managedObjectContext obtainPermanentIDsForObjects:@[person] error:&error];
    
    if (!success) {
        NSLog(@"[error] couldn't obtain permanent ID: %@", error);
        return;
    }
    
    success = [self flushUnsavedChanges:&error];
    
    if (!success) {
        NSLog(@"[error] couldn't flush unsaved changes: %@", error);
        return;
    }
 
    NSManagedObjectID *personID = person.objectID;
    
    NSLog(@"person: %@ (%@, %@)", personID, person.firstName, person.lastName);
    
    self.managedObjectContext = nil;
    self.rootManagedObjectContext = nil;
    self.persistentStoreCoordinator = nil;
    self.managedObjectModel = nil;
    
    person = (Person *)[self.managedObjectContext objectWithID:personID];
    NSLog(@"loaded person: %@ (%@, %@)", personID, person.firstName, person.lastName);

    NSLog(@" ");
    NSLog(@"--------- 2nd try without temporary object --------");
    NSLog(@" ");
    
    entity = [NSEntityDescription entityForName:@"Person"
                         inManagedObjectContext:self.managedObjectContext];

    
    person = (Person *)[[NSManagedObject alloc] initWithEntity:entity
                                insertIntoManagedObjectContext:self.managedObjectContext];
    person.firstName = @"Maude";
    person.lastName  = @"Lebowski";
    
    success = [self.managedObjectContext obtainPermanentIDsForObjects:@[person] error:&error];
    
    if (!success) {
        NSLog(@"[error] couldn't obtain permanent ID: %@", error);
        return;
    }
    
    success = [self flushUnsavedChanges:&error];
    
    if (!success) {
        NSLog(@"[error] couldn't flush unsaved changes: %@", error);
        return;
        
    }
    
    personID = person.objectID;
    
    NSLog(@"person: %@ (%@, %@)", personID, person.firstName, person.lastName);
    
    self.managedObjectContext = nil;
    self.rootManagedObjectContext = nil;
    self.persistentStoreCoordinator = nil;
    self.managedObjectModel = nil;
    
    person = (Person *)[self.managedObjectContext objectWithID:personID];
    NSLog(@"loaded person: %@ (%@, %@)", personID, person.firstName, person.lastName);
}

@end
