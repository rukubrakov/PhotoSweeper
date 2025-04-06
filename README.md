# Photo Duel — iOS App to Clean Up Photos

This is an open-source iOS app designed to help users clean up their photo library by making simple pairwise choices.

## 🚀 Idea

Two photos are shown side by side. The user picks the one they want to keep — the other gets deleted. The goal is to quickly and easily reduce photo clutter.

## 📱 Built With

- Swift
- SwiftUI
- Xcode
- GitHub Copilot

## 📦 Features (MVP)

- Display two consecutive photos
- Tap to choose which one to keep
- Delete the unchosen one from library
- Basic local permissions handling

## 🔜 Future Ideas

- Smart photo pairing (e.g., similar content detection)
- Progress tracking
- Undo recent deletion
- iCloud photo support

## 🛠 Getting Started

To build this app, open `PhotoDuel.xcodeproj` in Xcode and run it on a simulator or a real device with photo access permission.

---

This project is in early development. Contributions and feedback are welcome!

SPECIFICATION

1. Project Overview
App Name (Working Title): SwipeClean

Purpose:
Provide a simple, fast, and intuitive “tinder-like” workflow to clean up duplicate or near-duplicate photos in the iPhone’s camera roll. The app will display pairs of similar images and allow the user to decide which one to keep or discard.

Core Mechanics:

Swipe Up: Keep the top photo, remove the bottom one.

Swipe Down: Remove the top photo, keep the bottom one.

Restore Button: Undo the last removal action (in case the user made a mistake).

Skip Button: Keep both photos and move on to the next pair.

2. Functional Requirements
2.1. User Interface (UI) and User Experience (UX)
Home Screen

Simple layout with a “Start Cleaning” button.

Settings icon to configure user preferences (e.g., skip distance threshold, whether or not to confirm before deletion, default restoration behavior, etc.).

Swipe Screen (Main Screen)

Two images displayed: one on the upper half and one on the lower half of the screen.

Clear swipe guidance:

Swipe up → Keep top, discard bottom.

Swipe down → Discard top, keep bottom.

Central buttons overlay (optionally near the middle or bottom, for easy reach):

Restore: Restores the most recently removed photo, reversing the last action.

Skip: Keeps both photos and moves to the next pair.

Progress or status indicator (e.g., “Photo Pair 5/100”).

Smooth animations for the swipe gestures.

Confirmation/Feedback Toasts or Banners

Confirm removal and keeping status with a subtle banner or toast message (“Bottom photo removed”, “Top photo removed”, etc.).

Notify user on successful restore (“Last photo restored”).

Settings Screen (optional if needed)

Option to set a threshold for similarity distance (controls how “close” images must be to appear as pairs).

Toggle for enabling/disabling a final confirmation step before deleting photos from the iPhone library.

Toggle or advanced settings for controlling CNN model usage or CPU/GPU usage (for advanced users).

2.2. Image Similarity & Pair Generation
Image Embedding/Feature Extraction

Use a simple CNN such as a pretrained ImageNet model (ResNet, MobileNet, or other).

For each image, extract a feature vector (e.g., 512D or 2048D depending on the chosen model).

Building a Similarity Index

After extracting feature vectors for all images, store them in a feature database (e.g., a local persistent store or a vector database on the device if performance allows).

For random sampling of similar pairs, choose images whose embeddings are close in Euclidean or cosine distance.

A threshold can be set for “distance closeness.”

Pair Selection Algorithm

Randomly sample a photo, then find its nearest neighbor(s) in embedding space.

Serve the pair to the user for the keep/remove decision.

Mark pairs as “already processed” so they are not re-served unless the user reverts or reindexes.

Consider a fallback for when there are no more pairs above the similarity threshold.

Handling iOS Photo Library

Integrate with iOS Photos framework to read, modify, or delete images from the user’s library.

Important: The app must request the user’s permission to access and modify photos.

A local caching mechanism for feature vectors (to avoid repeated computation).

2.3. Restoration and Skipping Logic
Restore Action

Maintain an “undo stack” of the last few user actions (perhaps the last action only, or up to N actions).

On pressing Restore, bring back the most recently removed photo to the user’s library and re-queue the pair for a decision or simply confirm the “restored” photo is safe.

If a user has performed multiple keep/remove actions since the last removal, define a limit for how many steps can be undone.

Skip Action

Keeps both photos in the library.

Move on to the next pair, which is either the next closest similar pair or the next random pair.

Data Persistence

Maintain a local log or database of performed actions to handle any rollback scenarios.

The log can track: which images were removed/kept, the timestamp, and the pair IDs.

2.4. Performance Considerations
On-Device vs. Server-Side Inference

If performance on device is feasible, use Core ML or a similar framework to do the feature extraction on the iPhone itself.

If the dataset (photo library) is large and the device is older, consider a lightweight CNN or even a remote server approach (though privacy concerns might arise).

Recommended: For small to medium photo libraries, on-device with a pretrained model is typically sufficient on modern iPhones.

Batch Processing

Extract feature embeddings in a background thread after the initial user grant of Photos access.

Update the user interface only after the embeddings for the entire library or a chunk are ready.

Memory Management

Large images can be downsampled or resized before passing them to the CNN.

Use caching for the embeddings, so each image is only processed once.

Deletion from Photo Library

When the user swipes away an image, it is removed from the iOS Photos library. By default, iOS moves images to the “Recently Deleted” folder, allowing for some short-term system-level restore.

The app can rely on iOS’s built-in “Recently Deleted” or implement an additional layer of “soft delete” to ensure easy rollback.

3. Non-Functional Requirements
Privacy and Security

Clearly inform the user about how you process images (on-device or remote).

If using any remote server approach, ensure encrypted transfer of images.

Comply with Apple’s guidelines for user data privacy.

Usability

The interface should be simple with minimal friction.

Gestures and button placement should be intuitive (e.g., large swipe areas, easy-to-access restore/skip buttons).

Scalability

Should handle libraries of up to several thousand images comfortably.

Feature extraction might take time for huge libraries; consider progress indicators or partial indexing solutions.

Maintainability

Code structure should cleanly separate the logic for the CNN/feature extraction from the UI.

Maintain a modular architecture for easily upgrading the similarity model later.

4. Architecture & Technical Details
Recommended Development Environment

IDE: Xcode (the standard for iOS development).

Language: Swift (preferred for modern iOS apps).

Framework: SwiftUI or UIKit (SwiftUI is recommended for quicker prototyping and a more declarative UI, but UIKit is still viable if your team is more comfortable with it).

App Architecture

Model-View-ViewModel (MVVM) if using SwiftUI, or MVC / MVVM for UIKit.

Separate modules for:

PhotoProcessing (CNN embeddings, similarity logic).

DataManagement (indexing, logging user actions).

UI (SwiftUI or UIKit views and view controllers).

Service (for bridging iOS Photos framework calls).

CNN Integration

Use Core ML with a pretrained model (like MobileNetV2 or ResNet50) converted to Core ML format.

For each image, feed a resized (e.g., 224×224) version to the model to get a feature vector.

Store feature vectors in a local data store (e.g., SQLite, Realm, CoreData, or even an in-memory store if feasible).

Distance Computation

Cosine similarity or Euclidean distance between feature vectors.

If you have many images, consider an approximate nearest neighbor library such as FAISS (although that typically runs on Python/C++— you may integrate in a specialized manner or do a simpler approach in Swift if the library size is not too large).

Deletion Handling

Use PHPhotoLibrary and PHAsset changes for permanent deletion from the user’s library once the user confirms or after a certain number of days.

Provide clear warnings or rely on “Recently Deleted” so the user can recover if they made a mistake and the app’s internal restore function doesn’t suffice.

Undo/Restore Mechanism

Keep a lightweight stack with references to the last removed photo’s ID.

On pressing Restore, re-insert that photo into the library if possible or instruct iOS to “undelete” from “Recently Deleted” (this often requires special handling).

Alternatively, use an internal “soft delete” where the photo is not immediately removed from the Photos library, but flagged for deletion. Then a daily or weekly batch job can finalize removals.

5. Additional Considerations
Testing

Test with libraries of various sizes and image types.

Ensure that UI gestures are smooth and consistent across devices (iPhone 8 up to the latest models).

Verify that the restore function works correctly even after the app is backgrounded or closed.

App Store Guidelines

Make sure to provide a clear usage description for the Photos library in Info.plist (e.g., NSPhotoLibraryUsageDescription).

Follow Apple’s Human Interface Guidelines for gesture-based interactions.

Performance Optimizations

Preprocessing images in a background queue.

Possibly limit the comparison dimension of the embedding (e.g., using a PCA or some dimensionality reduction if needed).

On-device scheduling for model inference (use DispatchQueue.global(qos: .userInitiated) or DispatchQueue.background as appropriate).

Monetization / In-App Purchases (Optional)

Potentially offer advanced features like more frequent indexing or advanced editing functionalities.

A free tier for basic usage and a premium subscription for advanced similarity scanning or unlimited photo scanning if that’s part of your business model.

Localization

Support multiple languages for text and instructions if the target market is global.

All text strings should be localizable.

6. Example Development Workflow
Set Up Xcode Project

Create a new SwiftUI iOS project named “SwipeClean.”

Configure Info.plist with NSPhotoLibraryUsageDescription.

Implement Photo Access

Integrate PHPhotoLibrary to fetch user’s photos and store references (PHAsset).

Develop a method to convert PHAsset to UIImage or a buffer for CNN input.

Model Integration

Convert the chosen CNN model (e.g., MobileNetV2) to Core ML format if not already available.

Create a Swift class that loads the model, processes UIImages to produce embeddings.

Feature Extraction and Database

On initial launch, gather all photos, extract embeddings, and store them in a local database (e.g., a simple SQLite or Realm table: photo_id, embedding_vector).

Show a progress bar or “indexing photos” message during this step.

Similarity Logic

Implement a function to find the top N nearest neighbors for each photo.

Randomly select pairs from among those neighbors to display to the user.

Swipe Screen

Set up the SwiftUI UI with a “card stack” or a custom gesture recognizer to handle swipes up/down.

Integrate the logic for keep/remove and skip.

Implement an “undo” stack for restore functionality.

Testing & Refinement

Thoroughly test the gesture interactions, image display, restore logic, and final library updates.

Optimize for performance if scanning thousands of images.

Beta Release

Distribute via TestFlight to gather feedback before public App Store release.

7. Conclusion
By following these specifications, you will have a robust foundation for building an iPhone application that allows users to clean their photo library in a fun, interactive, swipe-based manner. Key points include leveraging Apple’s ecosystem (Xcode, SwiftUI, Core ML, and the Photos framework), extracting and storing feature vectors for similarity-based pair generation, and carefully managing the user’s library with transparent restore/delete operations.

This architecture ensures a user-friendly experience, clear separation of concerns, and enough flexibility to integrate more advanced or optimized models down the road.