//
//  Drawable.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 23/06/21.
//

import Foundation

public protocol Drawable{
    var geometry : Geometry{get}
    var identifier : Int {get}
    var material : Material {get set}
}
