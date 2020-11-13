import UIKit

public enum ImageUploadSanitizer {
    
    private static let maxSize = CGSize(width: 3840, height: 3840)
    
    public static func sanitizedImage(from rawImage: UIImage) -> (image: UIImage?, data: Data?) {
        guard let rawData = rawImage.jpegData(compressionQuality: JPEGCompressionQuality.high) else {
            return (nil, nil)
        }
        if rawData.count < 2 * bytesPerMegaByte || max(rawImage.size.width, rawImage.size.height) < 1920 {
            return (rawImage, rawData)
        } else {
            let newSize = rawImage.size.sizeThatFits(maxSize)
            let newImage = rawImage.imageByScaling(to: newSize)
            let newData = newImage?.jpegData(compressionQuality: JPEGCompressionQuality.high)
            return (newImage, newData)
        }
    }
    
}
