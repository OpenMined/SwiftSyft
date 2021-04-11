//
//  LossChartViewController.swift
//  SwiftSyft_Example
//
//  Created by Mark Jeremiah Jimenez on 24/04/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import Charts
import Combine

class LossChartViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var cycleCompletedLabel: UILabel!

    let lossSubject: PassthroughSubject<Float, Error> = PassthroughSubject<Float, Error>()
    var lossValues: [Float] = [Float]()
    var disposeBag: Set<AnyCancellable> = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Line chart style from https://github.com/danielgindi/Charts/blob/master/ChartsDemo-iOS/Swift/Demos/LineChart1ViewController.swift
        self.lineChartView.chartDescription?.enabled = false
        self.lineChartView.dragEnabled = true
        self.lineChartView.setScaleEnabled(true)
        self.lineChartView.pinchZoomEnabled = true

        self.lineChartView.xAxis.gridLineDashLengths = [10, 10]
        self.lineChartView.xAxis.gridLineDashPhase = 0

        let leftAxis = lineChartView.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.axisMaximum = 2.33
        leftAxis.axisMinimum = 0.0
        leftAxis.gridLineDashLengths = [5, 5]
        leftAxis.drawLimitLinesBehindDataEnabled = true

        lineChartView.rightAxis.enabled = false

        lineChartView.legend.form = .line

        self.lossSubject.receive(on: DispatchQueue.main).sink(receiveCompletion: { result in

            switch result {
            case .finished:
                self.cycleCompletedLabel.isHidden = false
            default:
                break
            }

        }, receiveValue: { [weak self] loss in

            if let self = self {
                self.lossValues.append(loss)
                self.setDataCount(lossValues: self.lossValues)
            }

        }).store(in: &self.disposeBag)

//        self.setDataCount(lossValues: self.lossValues)

        lineChartView.animate(xAxisDuration: 2.5)

    }

    func setDataCount(lossValues: [Float]) {

        let values = lossValues.enumerated().map { (index, loss) -> ChartDataEntry in
            return ChartDataEntry(x: Double(index), y: Double(loss))
        }

        let set1 = LineChartDataSet(entries: values, label: "Loss")
        set1.drawIconsEnabled = false

        set1.lineDashLengths = [5, 2.5]
        set1.highlightLineDashLengths = [5, 2.5]
        set1.setColor(.black)
        set1.setCircleColor(.black)
        set1.lineWidth = 1
        set1.circleRadius = 3
        set1.drawCircleHoleEnabled = false
        set1.valueFont = .systemFont(ofSize: 9)
        set1.formLineDashLengths = [5, 2.5]
        set1.formLineWidth = 1
        set1.formSize = 15

        let gradientColors = [ChartColorTemplates.colorFromString("#00ff0000").cgColor,
                              ChartColorTemplates.colorFromString("#ffff0000").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!

        set1.fillAlpha = 1
        set1.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        set1.drawFilledEnabled = true

        let data = LineChartData(dataSet: set1)

        self.lineChartView.data = data
    }

}
