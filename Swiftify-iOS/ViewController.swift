//
//  ViewController.swift
//  Swiftify-iOS
//
//  Created by Peter Marton on 19/09/14.
//  Copyright (c) 2014 Peter Marton. All rights reserved.
//

import UIKit
import QuartzCore
import JavaScriptCore
import Darwin


class ViewController: UIViewController {
    
    let MIN_TEMP = 66.0
    let REF_TEMP = 67.0
    
    @IBOutlet weak var pwmView: UIView!
    @IBOutlet weak var tempView: UIView!
    var lineChartTemp: LineChart?
    var lineChartPWM: LineChart?
    
    var views: Dictionary<String, AnyObject> = [:]
    var dataTemp: Array<CGFloat> = []
    var dataPWM: Array<CGFloat> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load javascript file in String
        let path = NSBundle.mainBundle().pathForResource("bundle", ofType: "js")
        var jsSource: String! = String.stringWithContentsOfFile(path!)
        
        // Make browserify to work
        jsSource = "var window = this; \(jsSource)"
        
        // create a javascript context environment and evaluate script
        var context = JSContext()
        
        context.evaluateScript(jsSource)
        
        
        // JSON parsing
        let calculate = context.objectForKeyedSubscript("calculate")
        let JSON = context.objectForKeyedSubscript("JSON")
        let JSONparse = JSON.objectForKeyedSubscript("parse")
        
        let parsed = JSONparse.callWithArguments(["{\"foo\":\"bar\",\"bar\":[1,2],\"world\":{\"hello\":4,\"foo\":\"bar\"}}"])
        let parsedDic = parsed.toDictionary()
        
        // Simulate temp
        let setPoint = context.objectForKeyedSubscript("setPoint")
        setPoint.callWithArguments([REF_TEMP])
        
        var temp = MIN_TEMP
        var amplitude = 0.3;       // wave amplitude
        var freq = 1.0;            // angular frequency
        
        for var index = -1.0; index < 1.0; index += 0.1 {
            let deltaTemp = sin(freq * (index)) * amplitude;
            
            temp -= deltaTemp
            
            let output = calculate.callWithArguments([temp]).toNumber()
            
            self.dataTemp.append(CGFloat(temp));
            self.dataPWM.append((output / 10));
        }
        
        // Temp chart
        lineChartTemp = LineChart()
        lineChartTemp!.areaUnderLinesVisible = true
        lineChartTemp!.labelsYVisible = true
        lineChartTemp!.axisInset = 40
        lineChartTemp!.addLine(dataTemp)
        lineChartTemp!.setTranslatesAutoresizingMaskIntoConstraints(false)
        views["lineChartTemp"] = lineChartTemp
        tempView.addSubview(lineChartTemp!)
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[lineChartTemp]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[lineChartTemp]-|", options: nil, metrics: nil, views: views))
        
        // PWM chart
        lineChartPWM = LineChart()
        lineChartPWM!.areaUnderLinesVisible = true
        lineChartPWM!.labelsYVisible = true
        lineChartPWM!.axisInset = 40
        lineChartPWM!.addLine(dataPWM)
        lineChartPWM!.setTranslatesAutoresizingMaskIntoConstraints(false)
        views["lineChartPWM"] = lineChartPWM
        pwmView.addSubview(lineChartPWM!)
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[lineChartPWM]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[lineChartPWM]-|", options: nil, metrics: nil, views: views))
        
    }
    
    
    /**
    * Redraw chart on device rotation.
    */
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if let chart = lineChartTemp {
            chart.setNeedsDisplay()
        }
        if let chart = lineChartPWM {
            chart.setNeedsDisplay()
        }
    }
}

