//
//  Material.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 24/06/21.
//

import MetalKit

public enum LightingModel : Int32{
    case phong = 0
    case lambert = 1
    case constant = 2
    case flatColor = 3

}

public struct Material {
    
    public var ambient : Any
    public var diffuse : Any
    public var specular : Any
    public var shininess : Float
    public var model : LightingModel
    
    static public var deafultMaterial = {return Material(ambient: vec3(1,1,1), diffuse: vec3(1,1,1), specular: vec3(1,1,1), shininess: 32, model: .phong)}()
    
    public func asTextures(device : MTLDevice) -> [MTLTexture]{
        
        var textures = [MTLTexture]()
        textures.reserveCapacity(3)
        
        for  element in [ambient, diffuse, specular]{
            
            if let color = element as? vec3{
                textures.append(device.makeSolidColorTexture(color: color, width: 1, height: 1)!)
            }
            else if let texture = element as? MTLTexture{
                textures.append(texture)
            }
            else{
                textures.append(device.makeSolidColorTexture(color: vec3(1,1,1), width: 1, height: 1)!)
            }
        }
        
        return textures
    }
    
}


extension MTLDevice{
    
    public func makeSolidColorTexture(color : vec3, width : Int, height: Int) -> MTLTexture?{
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.width  =  Int(1)
        textureDescriptor.height = Int(1)
        textureDescriptor.pixelFormat = .rgba8Unorm
        #if targetEnvironment(macCatalyst)
        textureDescriptor.storageMode = .managed
        #else
        textureDescriptor.storageMode = .shared
        #endif
        textureDescriptor.usage = [.shaderRead]
        
        let texture = self.makeTexture(descriptor: textureDescriptor)!
        
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
        let region = MTLRegion(origin: origin, size: size)
        let mappedColor = simd_uchar4(vec4(color*255, 1))
        Array<simd_uchar4>(repeating: mappedColor, count: 64).withUnsafeBytes { ptr in
            texture.replace(region: region, mipmapLevel: 0, withBytes: ptr.baseAddress!, bytesPerRow: 32)
        }
        
        return texture
    }
    
}
