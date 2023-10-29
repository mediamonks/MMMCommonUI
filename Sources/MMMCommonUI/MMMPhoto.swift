//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2023 MediaMonks. All rights reserved.
//

import Foundation

/// A photo that vends the same image regardless of the requested size.
///
/// This can be handy when implementing APIs involving `MMMPhoto` while having only a single image.
/// (It could be useful to proxy it and do downscaling, but that could only help with rendering
/// and would not improve overall memory usage as we would be still holding the original image.)
public final class MMMPhotoFromLoadableImage: NSObject, MMMPhoto {

	public let image: MMMLoadableImage

	public init(_ image: MMMLoadableImage) {
		self.image = image
	}

	public func image(forTargetSize targetSize: CGSize, contentMode: MMMPhotoContentMode) -> MMMLoadableImage {
		self.image
	}
}

/// A photo that is always failing to load.
///
/// Sometimes we need to implement a non-optional `MMMPhoto` without having an image. Returning an always failing
/// to load image is better in this case as it would allow to fall back to a placeholder of the corresponding image view.
public final class MMMEmptyPhoto: NSObject, MMMPhoto {

	// Using the property of `MMMPublicLoadableImage` to quickly fail for `nil` images.
	private lazy var image = MMMPublicLoadableImage(url: nil)

	public func image(forTargetSize targetSize: CGSize, contentMode: MMMPhotoContentMode) -> MMMLoadableImage {
		self.image
	}
}
