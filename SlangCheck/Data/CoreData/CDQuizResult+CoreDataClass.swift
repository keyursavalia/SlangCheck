// Data/CoreData/CDQuizResult+CoreDataClass.swift
// SlangCheck
//
// NSManagedObject subclass for the CDQuizResult CoreData entity.
// Manual implementation — Xcode codegen disabled (codeGenerationType="none").
//
// DEVELOPER ACTION REQUIRED:
// Add the "CDQuizResult" entity to SlangCheckData.xcdatamodeld with these attributes:
//   id               UUID       Non-Optional
//   correctCount     Integer 64 Non-Optional  default: 0
//   totalCount       Integer 64 Non-Optional  default: 1
//   hintsUsed        Integer 64 Non-Optional  default: 0
//   elapsedSeconds   Double     Non-Optional  default: 0
//   auraPointsEarned Integer 64 Non-Optional  default: 0
//   completedAt      Date       Non-Optional

import CoreData
import Foundation

/// CoreData managed object representing one completed quiz session result.
/// Append-only — records are never updated after insertion.
/// Never exposed outside the `Data/` layer.
@objc(CDQuizResult)
public final class CDQuizResult: NSManagedObject {}
