This is a sample project!
=========================

This project shows, how inserting objects via

```Objective-C
Person *person = (Person *)[[NSManagedObject alloc] initWithEntity:entity
                                    insertIntoManagedObjectContext:nil];
    
person.firstName = @"Bunny";
person.lastName  = @"Lebowski";
    
[self.managedObjectContext insertObject:person];
```

results in data loss.

The Core Data stack is setup to have:
  - a root ``NSManagedObjectContext`` that is bound to the ``NSPersistentStoreCoordinator``
  - a sub-``NSManagedObjectContext`` that has the root context as ``parentContext``

Please look into ``-[CBHMTAppDelegate test:]`` for the test code and ``-[CBHMTAppDelegate flushUnsavedChanges]`` for the saving code.

It consists of two tests:
 
  - creation of the ``Person`` as temporary object first
  - creation of the ``Person`` as an inserted object afterwards

The method that flushes unsaved changes outputs the ``-[NSManagedObjectContext insertedObjects]`` to the console. This shows that in the first case, the values are not pushed to the root context.

**Results**

```
using database: /Users/christian/Library/Application Support/Test/Database/Test.sqlite
2a >> has changes: {(
    <Person: 0x101a59420> (entity: Person; id: 0x101a5c6a0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p7> ; data: {
    firstName = Bunny;
    lastName = Lebowski;
})
)}
2b >> has changes: {(
    <Person: 0x10190b150> (entity: Person; id: 0x101a5c6a0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p7> ; data: {
    firstName = nil;
    lastName = nil;
})
)}
person: 0x101a5c6a0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p7> (Bunny, Lebowski)
loaded person: 0x101a5c6a0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p7> ((null), (null))

--------- 2nd try without temporary object --------

2a >> has changes: {(
    <Person: 0x100548bf0> (entity: Person; id: 0x10199ade0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p8> ; data: {
    firstName = Maude;
    lastName = Lebowski;
})
)}
2b >> has changes: {(
    <Person: 0x101a69f10> (entity: Person; id: 0x10199ade0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p8> ; data: {
    firstName = Maude;
    lastName = Lebowski;
})
)}
person: 0x10199ade0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p8> (Maude, Lebowski)
loaded person: 0x10199ade0 <x-coredata://37FCE53B-9119-4C45-93EA-A91A99552877/Person/p8> (Maude, Lebowski)
```
