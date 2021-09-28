//
//  Camera.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

import Foundation
import simd

public enum ProjectionType {
    case Perspective
    case Orthographic
}

public protocol CameraSettings{
    var aspectRatio : Float {get set}
    var near : Float {get set}
    var far : Float {get set}
}

public struct PerspectiveSettings : CameraSettings{
    public var fov : Float
    public var aspectRatio : Float
    public var near : Float
    public var far : Float
    
    public static func defaultSettings() -> PerspectiveSettings{
        return PerspectiveSettings(fov: 45, aspectRatio: 10.0/7.0, near: 0.1, far: 100)
    }
}

public struct OrthographicSettings : CameraSettings{
    public var left : Float
    public var right : Float
    public var top : Float
    public var bottom : Float
    public var near : Float
    public var far : Float
    public var aspectRatio : Float
    public var zoom : Float
    
    public static func defaultSettings() -> OrthographicSettings{
        return OrthographicSettings(left: -2, right: 2, top: 2, bottom: -2, near: -5, far: 5, aspectRatio: 10.0/7.0, zoom: 1.78)
    }

}

public class Camera : Node{

    public var perspectiveSettings : PerspectiveSettings {didSet{projectionMatrix_ = nil}}
    public var orthographicSettings : OrthographicSettings {didSet{projectionMatrix_ = nil}}
    
    public var projectionType : ProjectionType {didSet{projectionMatrix_ = nil}}
    public var pivot = vec3(0,0,0)
    private var isRotating = false
    
    private var projectionMatrix_ : matrix4?
        
    public init(settings : PerspectiveSettings) {
        perspectiveSettings = settings
        orthographicSettings = OrthographicSettings.defaultSettings()
        self.projectionType = .Perspective
        super.init()
    }
    
    public init(settings : OrthographicSettings) {
        orthographicSettings = settings
        perspectiveSettings = PerspectiveSettings.defaultSettings()
        self.projectionType = .Orthographic
        super.init()
    }
    
    public func rotate(degrees : vec3){
        rotation += degrees
    }
    
    public func getCurrentSettings() -> CameraSettings{
        if projectionType == .Perspective{
            return perspectiveSettings
        }
        return orthographicSettings
    }
    
    public func setSettings(_ settings : CameraSettings){
        
        if let settings_ = settings as? PerspectiveSettings{
            perspectiveSettings = settings_
        }
        else{
            let settings_ = settings as! OrthographicSettings
            orthographicSettings = settings_
        }
        
    }
    
    public func projectionMatrix() -> matrix4 {
        
        guard let _ = projectionMatrix_ else{
            switch self.projectionType {
                case .Perspective:
                    let settings = perspectiveSettings
                    projectionMatrix_ = matrix4.perspectiveProjectionMatrix(angle: Float.degreeToRad(x: settings.fov),
                                                                            aspectRatio: settings.aspectRatio,
                                                                            near: settings.near,
                                                                            far: settings.far)
                default:
                    let settings = orthographicSettings
                    projectionMatrix_ = matrix4.orthographicProjectionMatrix(left: settings.left*settings.aspectRatio/settings.zoom, right: settings.right*settings.aspectRatio/settings.zoom, top: settings.top/settings.zoom, bottom: settings.bottom/settings.zoom, near: settings.near, far: settings.far)
                    
            }
            return projectionMatrix_!
        }
        return projectionMatrix_!

    }
    
    public func viewMatrix() -> matrix4{
        
        let model = matrix4.makeTranslation(x: -pivot.x, y: -pivot.y, z: -pivot.z)
        let view = matrix4.makeTranslation(x: self.position.x, y: self.position.y, z: self.position.z)
        let rotation = matrix4.makeRotation(x: self.rotation.x, y: self.rotation.y, z: self.rotation.z)
        
        let mp = model*vec4(pivot.x, pivot.y, pivot.z, 1)
        let pivotTranslation = matrix4.makeTranslation(x: -mp.x, y: -mp.y, z: -mp.z)
        
        return view*pivotTranslation*rotation*model
    }
    
    
}
