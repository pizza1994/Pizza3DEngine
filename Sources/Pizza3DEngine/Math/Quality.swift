//
//  File.swift
//  
//
//  Created by Luca Pitzalis on 27/01/22.
//

import Foundation
import simd

func determinant(c0 : vec3, c1 : vec3, c2 : vec3) -> Float{
    return dot(c0, cross(c1, c2))
}

func hexScaledJacobian(p0 : vec3, p1 : vec3, p2 : vec3, p3 : vec3,
                         p4 : vec3, p5: vec3, p6 : vec3, p7 : vec3) -> Float{
    
    let l0  = normalize(p1-p0)
    let l1  = normalize(p2-p1)
    let l2  = normalize(p3-p2)
    let l3  = normalize(p3-p0)
    let l4  = normalize(p4-p0)
    let l5  = normalize(p5-p1)
    let l6  = normalize(p6-p2)
    let l7  = normalize(p7-p3)
    let l8  = normalize(p5-p4)
    let l9  = normalize(p6-p5)
    let l10 = normalize(p7-p6)
    let l11 = normalize(p7-p4)
    
    let x0 = normalize((p1-p0) + (p2-p3) + (p5-p4) + (p6-p7))
    let x1 = normalize((p3-p0) + (p2-p1) + (p7-p4) + (p6-p5))
    let x2 = normalize((p4-p0) + (p5-p1) + (p6-p2) + (p7-p3))

    var sj = [Float]()
    sj.reserveCapacity(9)
    
    let st = [[l0, l3, l4], [l1, -l0, l5], [l2, -l1, l6], [-l3, -l2, l7],
              [l11, l8, -l4], [-l8, l9, -l5], [-l9, l10, -l6], [-l10,-l11, -l7],
              [x0, x1, x2]]
    
    for (i, el) in st.enumerated(){
        sj[i] = determinant(c0: el[0], c1: el[1], c2: el[2])
    }
    
    let msj_ = sj.min()
    guard let msj = msj_ else{return -1}
    return msj > 1.0001 ? -1 : msj
    
}

func tetScaledJacobian(p0 : vec3, p1 : vec3, p2 : vec3, p3 : vec3) -> Float{
    
    let l0 = p1-p0
    let l1 = p2-p1
    let l2 = p0-p2
    let l3 = p3-p0
    let l4 = p3-p1
    let l5 = p3-p2
    
    let l0_l = length(l0)
    let l1_l = length(l1)
    let l2_l = length(l2)
    let l3_l = length(l3)
    let l4_l = length(l4)
    let l5_l = length(l5)
    
    let J = dot((cross(l2, l0)), l3)
    
    let lambda = [l0_l*l2_l*l3_l, l0_l*l1_l*l4_l, l1_l*l2_l*l5_l, l3_l*l4_l*l5_l]
    
    let max_ = lambda.max()
    guard let max = max_ else{return -1}
    
    return max < -Float.infinity ? -1 : (J*Float(2.squareRoot()) / max)

    
}
