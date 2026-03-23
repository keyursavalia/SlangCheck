// Data/Firebase/FirebaseUserProfileRepository.swift
// SlangCheck
//
// Firestore + Firebase Storage implementation of UserProfileRepository.
//
// Firestore document path : users/{uid}
// Firebase Storage path   : profile_photos/{uid}
//
// ── Apply these rules in the Firebase console ──────────────────────────────
//
// Firestore (firestore.rules):
//   rules_version = '2';
//   service cloud.firestore {
//     match /databases/{database}/documents {
//       match /users/{uid} {
//         // Owner can read and write their own document.
//         allow write: if request.auth != null && request.auth.uid == uid;
//         // Any authenticated user can read (needed for future leaderboard).
//         allow read:  if request.auth != null;
//       }
//     }
//   }
//
// Firebase Storage (storage.rules):
//   rules_version = '2';
//   service firebase.storage {
//     match /b/{bucket}/o {
//       match /profile_photos/{uid} {
//         // Public reads — users can view each other's photos from future profile screens.
//         allow read;
//         // Only the owner can upload; hard cap at 1 MB.
//         allow write: if request.auth != null
//                      && request.auth.uid == uid
//                      && request.resource.size < 1 * 1024 * 1024;
//       }
//     }
//   }
// ────────────────────────────────────────────────────────────────────────────

#if canImport(FirebaseFirestore) && canImport(FirebaseStorage)

import FirebaseFirestore
import FirebaseStorage
import Foundation
import OSLog

// MARK: - FirebaseUserProfileRepository

/// Production `UserProfileRepository` backed by Firestore and Firebase Storage.
public struct FirebaseUserProfileRepository: UserProfileRepository {

    public init() {}

    // MARK: - Firestore Reference

    private func ref(uid: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    // MARK: - UserProfileRepository

    public func fetchProfile(uid: String) async throws -> UserProfile? {
        do {
            let snap = try await ref(uid: uid).getDocument()
            guard snap.exists, let data = snap.data() else { return nil }
            return decode(data, uid: uid)
        } catch {
            Logger.app.error("fetchProfile failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(error.localizedDescription)
        }
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        do {
            try await ref(uid: profile.id).setData(encode(profile))
        } catch {
            Logger.app.error("saveProfile failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(error.localizedDescription)
        }
    }

    public func updateDisplayName(_ name: String, uid: String) async throws {
        do {
            try await ref(uid: uid).updateData(["displayName": name])
        } catch {
            Logger.app.error("updateDisplayName failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(error.localizedDescription)
        }
    }

    public func updatePhotoURL(_ url: URL, uid: String) async throws {
        do {
            try await ref(uid: uid).updateData(["photoURL": url.absoluteString])
        } catch {
            Logger.app.error("updatePhotoURL failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(error.localizedDescription)
        }
    }

    public func uploadProfilePhoto(data: Data, uid: String) async throws -> URL {
        let storageRef = Storage.storage().reference().child("profile_photos/\(uid)")
        let metadata   = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            _ = try await storageRef.putDataAsync(data, metadata: metadata)
            let url = try await storageRef.downloadURL()
            Logger.app.info("Profile photo uploaded. uid=\(uid)")
            return url
        } catch {
            Logger.app.error("uploadProfilePhoto failed: \(error.localizedDescription)")
            throw UserProfileError.uploadFailed(error.localizedDescription)
        }
    }

    public func deleteProfile(uid: String) async throws {
        do {
            try await ref(uid: uid).delete()
            Logger.app.info("Profile Firestore document deleted. uid=\(uid)")
        } catch {
            Logger.app.error("deleteProfile failed: \(error.localizedDescription)")
            throw UserProfileError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Encode / Decode

    private func encode(_ p: UserProfile) -> [String: Any] {
        var data: [String: Any] = [
            "id":          p.id,
            "username":    p.username,
            "displayName": p.displayName,
            "email":       p.email,
            "auraPoints":  p.auraPoints,
            "createdAt":   Timestamp(date: p.createdAt)
        ]
        if let url = p.photoURL { data["photoURL"] = url.absoluteString }
        return data
    }

    private func decode(_ data: [String: Any], uid: String) -> UserProfile? {
        guard
            let username    = data["username"]    as? String,
            let displayName = data["displayName"] as? String,
            let email       = data["email"]       as? String
        else { return nil }

        let auraPoints = data["auraPoints"] as? Int    ?? 0
        let createdAt  = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let photoURL   = (data["photoURL"]  as? String).flatMap { URL(string: $0) }

        return UserProfile(
            id:          uid,
            username:    username,
            displayName: displayName,
            email:       email,
            photoURL:    photoURL,
            auraPoints:  auraPoints,
            createdAt:   createdAt
        )
    }
}

#endif // canImport(FirebaseFirestore) && canImport(FirebaseStorage)
