//
//  textureIO.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 25/06/21.
//

import Foundation
import MetalKit

public func loadTexture(url : URL) throws -> MTLTexture? {
    
    let textureLoader = MTKTextureLoader(device: Renderer.device!)
    
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
        [.origin: MTKTextureLoader.Origin.bottomLeft, .SRGB: false]
    
    let texture =
        try textureLoader.newTexture(URL: url,
                                     options: textureLoaderOptions)
    print("loaded texture: \(url.lastPathComponent)")
    return texture
}
