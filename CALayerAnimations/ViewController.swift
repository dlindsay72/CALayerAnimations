//
//  ViewController.swift
//  CALayerAnimations
//
//  Created by Dan Lindsay on 2017-01-10.
//  Copyright © 2017 Dan Lindsay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let layer = SpinMeLayer(withNumberOfItems: 6)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.darkGray
        view.layer.addSublayer(layer)
        layer.color = UIColor.white
        spin(nil)
        
        
        
    }
    
    @IBAction func spin(_ sender: AnyObject?) {
        layer.startAnimating()
    }
    
    @IBAction func halt(_ sender: Any) {
        layer.stopAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

