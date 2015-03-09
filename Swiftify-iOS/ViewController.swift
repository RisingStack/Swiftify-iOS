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

	func newLineChartView() -> LineChart {
		let view = LineChart()
		view.areaUnderLinesVisible = true
		view.labelsYVisible = true
		view.axisInset = 40
		view.setTranslatesAutoresizingMaskIntoConstraints(false)
		return view;
	}

	func evaluateBrwosifiedJSString(jsSource :String) -> Void {

		var context = JSContext()

		context.evaluateScript(jsSource)

		let calculate = context.objectForKeyedSubscript("calculate")
		let JSON = context.objectForKeyedSubscript("JSON")
		let JSONparse = JSON.objectForKeyedSubscript("parse")
		let JSONString = "{\"foo\":\"bar\",\"bar\":[1,2],\"world\":{\"hello\":4,\"foo\":\"bar\"}}"

		let parsed = JSONparse.callWithArguments([JSONString])
		let parsedDic = parsed.toDictionary()

		// Simulate temp
		let setPoint = context.objectForKeyedSubscript("setPoint")
		setPoint.callWithArguments([REF_TEMP])

		var temp = MIN_TEMP
		var amplitude = 0.3;       // wave amplitude
		var freq = 1.0;            // angular frequency


		var dataTemp: Array<CGFloat> = []
		var dataPWM: Array<CGFloat> = []
		for var index = -1.0; index < 1.0; index += 0.1 {
			let deltaTemp = sin(freq * (index)) * amplitude;

			temp -= deltaTemp

			let output = calculate.callWithArguments([temp]).toDouble()

			dataTemp.append(CGFloat(temp));
			dataPWM.append(CGFloat(output / 10));
		}

		self.dataPWM = dataPWM;
		self.dataTemp = dataTemp;
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // load javascript file in String
		if let path = NSBundle.mainBundle().pathForResource("bundle", ofType: "js") {
			var jsSource : String = String(contentsOfFile:path)!
			jsSource = "var window = this; \(jsSource)"
			self.evaluateBrwosifiedJSString(jsSource)
		}

		// Temp chart
		let lineChartTemp = self.newLineChartView()
		lineChartTemp.addLine(self.dataTemp)
		views["lineChartTemp"] = lineChartTemp
		tempView.addSubview(lineChartTemp)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[lineChartTemp]-|", options: nil, metrics: nil, views: views))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[lineChartTemp]-|", options: nil, metrics: nil, views: views))

        // PWM chart
        let lineChartPWM = self.newLineChartView()
        lineChartPWM.addLine(self.dataPWM)
        views["lineChartPWM"] = lineChartPWM
        pwmView.addSubview(lineChartPWM)
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[lineChartPWM]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[lineChartPWM]-|", options: nil, metrics: nil, views: views))

		self.lineChartPWM = lineChartPWM;
		self.lineChartTemp = lineChartTemp;
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

