//
//  Geometry.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 23/06/21.
//

import Foundation

public protocol Geometry {
    
    func pickVert(point: vec3) -> Int
    func pickEdge(point: vec3) -> Int
    func pickFace(point: vec3) -> Int
    func pickPoly(point: vec3) -> Int
    
    func dig(id : Int)
    func undig(id : Int)
    func reset()
        
    var bbox : AABB {get}
    var didChange : Bool{get set}
    var isVolumetric : Bool{get}
    var isSurface : Bool{get}
    
    func slice(x : (Float, Float), y: (Float, Float), z: (Float, Float), invertX : Bool, invertY : Bool, invertZ : Bool)

}
