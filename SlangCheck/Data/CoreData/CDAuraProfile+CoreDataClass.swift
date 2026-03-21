// Data/CoreData/CDAuraProfile+CoreDataClass.swift
// SlangCheck
//
// NSManagedObject subclass for the CDAuraProfile CoreData entity.
// Manual implementation — Xcode codegen disabled (codeGenerationType="none").
//
// DEVELOPER ACTION REQUIRED:
// Add the "CDAuraProfile" entity to SlangCheckData.xcdatamodeld with these attributes:
//   id               UUID       Non-Optional
//   totalPoints      Integer 64 Non-Optional  default: 0
//   currentTierRaw   String     Non-Optional  default: "unc"
//   streak           Integer 64 Non-Optional  default: 0
//   lastActivityDate Date       Optional
//   displayName      String     Non-Optional  default: ""

import CoreData
import Foundation

/// CoreData managed object representing the locally-cached `AuraProfile`.
/// One record per authenticated user. Never exposed outside the `Data/` layer.
@objc(CDAuraProfile)
public final class CDAuraProfile: NSManagedObject {}
