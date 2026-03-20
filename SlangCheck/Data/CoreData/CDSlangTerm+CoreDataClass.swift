// Data/CoreData/CDSlangTerm+CoreDataClass.swift
// SlangCheck
//
// NSManagedObject subclass for the CDSlangTerm CoreData entity.
// Manual implementation — Xcode codegen is disabled (codeGenerationType="none")
// to give full control over the class definition.

import Foundation
import CoreData

/// CoreData managed object representing a single slang term in the persistent store.
/// Never exposed outside the `Data/` layer — the repository translates these to `SlangTerm`.
@objc(CDSlangTerm)
public final class CDSlangTerm: NSManagedObject {}
