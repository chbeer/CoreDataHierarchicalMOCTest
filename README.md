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

