//
//  HeartRateProcessorTests.swift
//  CardiorespiratoryFitnessTests
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import XCTest
@testable import CardiorespiratoryFitness
 
class HeartRateProcessorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParams() {
        XCTAssertEqual(highPassParameters.count, 56)
        XCTAssertEqual(lowPassParameters.count, 56)
    }
    
    func compare(_ array1: [Double], _ array2: [Double], accuracy: Double) -> Bool {
        XCTAssertEqual(array1.count, array2.count)
        guard array1.count == array2.count else { return false }
        for idx in 0..<array1.count {
            let lhv = array1[idx]
            let rhv = array2[idx]
            XCTAssertEqual(lhv, rhv, accuracy: accuracy, "\(idx)")
            guard abs(lhv - rhv) <= accuracy else { return false }
        }
        return true
    }
    
    func testInvalidSamplingRate() {
        let processor = CRFHeartRateSampleProcessor()
        XCTAssertFalse(processor.isValidSamplingRate(2))
    }
    
    func testLowPassFilterParams() {
        XCTAssertEqual(lowPassParameters.count, 56)

        guard let filter = lowPassParameters.filterParams(for: testData.roundedSamplingRate) else {
            XCTFail("Failed to the the low pass filter parameters")
            return
        }
        
        XCTAssertTrue(compare(filter.a, testData.a_lowpass, accuracy: 0.00000001))
        XCTAssertTrue(compare(filter.b, testData.b_lowpass, accuracy: 0.00000001))
    }
    
    func testHighPassFilterParams() {
        XCTAssertEqual(highPassParameters.count, 56)
        
        guard let filter = highPassParameters.filterParams(for: testData.roundedSamplingRate) else {
            XCTFail("Failed to the the low pass filter parameters")
            return
        }

        XCTAssertTrue(compare(filter.a, testData.a_highpass, accuracy: 0.00000001))
        XCTAssertTrue(compare(filter.b, testData.b_highpass, accuracy: 0.00000001))
    }
    
    func testLowPassFilter() {
        let processor = CRFHeartRateSampleProcessor()
        guard processor.isValidSamplingRate(testData.roundedSamplingRate) else {
            XCTFail("The low pass filter parameters were not parsed. See testLowPassFilterParams()")
            return
        }
        let lowPass = processor.passFilter(testData.input, samplingRate: testData.roundedSamplingRate, type: .low)
        XCTAssertTrue(compare(lowPass, testData.lowpass, accuracy: 0.0001))
    }
    
    func testHighPassFilter() {
        let processor = CRFHeartRateSampleProcessor()
        guard processor.isValidSamplingRate(testData.roundedSamplingRate) else {
            XCTFail("The low pass filter parameters were not parsed. See testHighPassFilterParams()")
            return
        }
        let highPass = processor.passFilter(testData.input, samplingRate: testData.roundedSamplingRate, type: .high)
        XCTAssertTrue(compare(highPass, testData.highpass, accuracy: 0.0001))
    }

    func testMeanCenteringFilter() {
        let processor = CRFHeartRateSampleProcessor()
        let mcf = processor.meanCenteringFilter(testData.input, samplingRate: testData.roundedSamplingRate)
        XCTAssertTrue(compare(mcf, testData.mcfilter, accuracy: 0.000001))
    }

    func testAutocorrelation() {
        let processor = CRFHeartRateSampleProcessor()
        let acf = processor.autocorrelation(testData.input)
        XCTAssertTrue(compare(acf, testData.acf, accuracy: 0.0001))
    }

    func testCalculateSamplingRate() {
        let processor = CRFHeartRateSampleProcessor()
        let samplingRate = processor.calculateSamplingRate(from: testHRData.hr_data)
        XCTAssertEqual(samplingRate, 59.980, accuracy: 0.001)
    }

    func testCalculateSamplingRate_12hz() {
        let processor = CRFHeartRateSampleProcessor()
        let samplingRate = processor.calculateSamplingRate(from: testHRData12hz.hr_data)
        XCTAssertEqual(samplingRate, 12.7279, accuracy: 0.0001)
    }
    
    func testCalculatedLag() {
        let processor = CRFHeartRateSampleProcessor()
        let minLag = processor.calculateMinLag(samplingRate: testData.samplingRate)
        XCTAssertEqual(minLag, testData.minLag)
        let maxLag = processor.calculateMaxLag(samplingRate: testData.samplingRate)
        XCTAssertEqual(maxLag, testData.maxLag)
    }

    func testEstimatedHR() {
        let processor = CRFHeartRateSampleProcessor()
        let testData = testHRData
        let samplingRate = processor.calculateSamplingRate(from: testData.hr_data)
        let roundedSamplingRate = Int(round(samplingRate))

        let key: ChannelKeys = .green
        let inputChunks: [[Double]] = testData.hrInputChunk(for: key)
        let expectedOutputs: [HRTuple] = testData.hr_estimates[key.stringValue]!
        XCTAssertEqual(inputChunks.count, expectedOutputs.count)
        guard inputChunks.count == expectedOutputs.count
            else {
                XCTFail("The test data is invalid")
                return
        }
        
        // Only check some of the results b/c the calculations are for a resting heart rate and all use
        // initial estimate or else they are invalid (Initial windows).
        for ii in 0..<min(10, expectedOutputs.count) {

            let filteredData = processor.getFilteredSignal(inputChunks[ii], samplingRate: roundedSamplingRate)
            XCTAssertNotNil(filteredData)
            if let input = filteredData {
                let (hr, confidence) = processor.getHR(from: input, samplingRate: samplingRate)
                if let expectedHR = expectedOutputs[ii].hr,
                    let expectedConfidence = expectedOutputs[ii].confidence {
                    XCTAssertEqual(hr, expectedHR, accuracy: 0.000001, "\(key) \(ii)")
                    XCTAssertEqual(confidence, expectedConfidence, accuracy: 0.0001, "\(key) \(ii)")
                }
                else {
                    XCTAssertEqual(hr, 0, "\(key) \(ii)")
                    XCTAssertEqual(confidence, 0, "\(key) \(ii)")
                }
            }
        }
    }
    
    func testEstimatedHR_12hz() {
        let processor = CRFHeartRateSampleProcessor()
        let testData = testHRData12hz

        let samplingRate = processor.calculateSamplingRate(from: testData.hr_data)
        let roundedSamplingRate = Int(round(samplingRate))
        
        let key: ChannelKeys = .green
        let inputChunks: [[Double]] = testData.hrInputChunk(for: key)
        let expectedOutputs: [HRTuple] = testData.hr_estimates[key.stringValue]!
        XCTAssertEqual(inputChunks.count, expectedOutputs.count)
        guard inputChunks.count == expectedOutputs.count
            else {
                XCTFail("The test data is invalid")
                return
        }
        
        // Only check some of the results b/c the calculations are for a resting heart rate and all use
        // initial estimate or else they are invalid (Initial windows).
        for ii in 0..<min(10, expectedOutputs.count) {
            
            let filteredData = processor.getFilteredSignal(inputChunks[ii], samplingRate: roundedSamplingRate)
            XCTAssertNotNil(filteredData)
            if let input = filteredData {
                let (hr, confidence) = processor.getHR(from: input, samplingRate: samplingRate)
                if let expectedHR = expectedOutputs[ii].hr,
                    let expectedConfidence = expectedOutputs[ii].confidence {
                    XCTAssertEqual(hr, expectedHR, accuracy: 0.000001, "\(key) \(ii)")
                    XCTAssertEqual(confidence, expectedConfidence, accuracy: 0.0001, "\(key) \(ii)")
                }
                else {
                    XCTAssertEqual(hr, 0, "\(key) \(ii)")
                    XCTAssertEqual(confidence, 0, "\(key) \(ii)")
                }
            }
        }
    }

    func testEarlierPeaks() {
        let processor = CRFHeartRateSampleProcessor()
        let data = testEarlierPeaksExample
        let samplingRate = data.generatedSamplingRate

        guard let output = processor.preprocessSamples(data.x, samplingRate: samplingRate)
            else {
                XCTFail("Failed to preprocess the input data")
                return
        }
        XCTAssertTrue(compare(Array(output.x.dropFirst()), data.xacf, accuracy: 0.00000001))
        XCTAssertEqual(output.minLag, data.minLag)
        XCTAssertEqual(output.maxLag, data.maxLag)
        XCTAssertEqual(output.x.min()!, data.xMin, accuracy: 0.00000001)
        XCTAssertEqual(output.x.max()!, data.xMax, accuracy: 0.00000001)
        XCTAssertEqual(data.xacf.max()!, data.xMax, accuracy: 0.00000001)
        XCTAssertTrue(compare(Array(output.y.dropFirst()), data.y_output, accuracy: 0.00000001))

        let bounds = processor.getBounds(y: output.y, samplingRate: samplingRate)

        XCTAssertEqual(bounds.hr_initial_guess, data.initialGuess, accuracy: 0.00000001)
        XCTAssertEqual(bounds.y_min, data.yMin, accuracy: 0.00000001)
        XCTAssertEqual(bounds.y_max, data.yMax, accuracy: 0.00000001)

        guard let peaks = processor.getAliasingPeakLocation(hr: bounds.hr_initial_guess,
                                                            actualLag: bounds.y_max_pos,
                                                            samplingRate: samplingRate,
                                                            minLag: output.minLag,
                                                            maxLag: output.maxLag)
            else {
                XCTFail("Failed to get peaks.")
                return
        }

        XCTAssertEqual(peaks.nPeaks, data.aliased_peak.nPeaks)
        XCTAssertEqual(peaks.earlier, data.aliased_peak.earlierPeaks)
        XCTAssertEqual(peaks.later, data.aliased_peak.laterPeaks)

        let (hr, confidence) = processor.getHR(from: data.x, samplingRate: samplingRate)

        XCTAssertEqual(hr, data.estimatedHR, accuracy: 0.00000001)
        XCTAssertEqual(confidence, data.estimatedConfidence, accuracy: 0.00000001)
    }

    func testLaterPeaks() {
        let processor = CRFHeartRateSampleProcessor()
        let data = testLaterPeaksExample
        let samplingRate = data.generatedSamplingRate

        guard let output = processor.preprocessSamples(data.x, samplingRate: samplingRate)
            else {
                XCTFail("Failed to preprocess the input data")
                return
        }
        XCTAssertTrue(compare(Array(output.x.dropFirst()), data.xacf, accuracy: 0.00000001))
        XCTAssertEqual(output.minLag, data.minLag)
        XCTAssertEqual(output.maxLag, data.maxLag)

        let bounds = processor.getBounds(y: output.y, samplingRate: samplingRate)

        XCTAssertEqual(bounds.hr_initial_guess, data.initialGuess, accuracy: 0.00000001)

        guard let peaks = processor.getAliasingPeakLocation(hr: bounds.hr_initial_guess,
                                                            actualLag: bounds.y_max_pos,
                                                            samplingRate: samplingRate,
                                                            minLag: output.minLag,
                                                            maxLag: output.maxLag)
            else {
                XCTFail("Failed to get peaks.")
                return
        }

        XCTAssertEqual(peaks.nPeaks, data.aliased_peak.nPeaks)
        XCTAssertEqual(peaks.earlier, data.aliased_peak.earlierPeaks)
        XCTAssertEqual(peaks.later, data.aliased_peak.laterPeaks)

        let (hr, confidence) = processor.getHR(from: data.x, samplingRate: samplingRate)

        XCTAssertEqual(hr, data.estimatedHR, accuracy: 0.00000001)
        XCTAssertEqual(confidence, data.estimatedConfidence, accuracy: 0.00000001)
    }
    
    func testSampleProcessing() {
        
        // TODO: syoung 04/30/2019 Reconcile the R-implementation with the mobile devices implementation
        // Because of some noise in the windowing that is used in *test* code for the R-implementation, the
        // data from those tests includes noise from the mean order filtering. That noise is dropped in the
        // mobile device implementation by filtering over a large sample and keeping only the 10 second window
        // after the noise introduced during filtering. Because I did not want to introduce that noise into
        // this version of the algorithm, I am instead using this "test" to write out the sample data that is
        // used in checking that the Android and iOS implementations match.

        // Because this test takes a while to run, and it's using data from a resting heart rate,
        // only process a subset of the data. syoung 04/16/2019
        let start = 30
        
        let expectedHRValues = [
            CRFHeartRateBPMSample(timestamp: 46.3200712493, bpm: 69.26537857647685, confidence: 0.8665728400250351, channel: .green),
            CRFHeartRateBPMSample(timestamp: 47.3206772493, bpm: 69.26537781379395, confidence: 0.864004456488016, channel: .green),
            CRFHeartRateBPMSample(timestamp: 48.3212832913, bpm: 67.9584831399785, confidence: 0.8768333193716425, channel: .green),
            CRFHeartRateBPMSample(timestamp: 49.3218892083, bpm: 69.26537780919945, confidence: 0.8797011803396284, channel: .red),
            CRFHeartRateBPMSample(timestamp: 50.3224952083, bpm: 67.95848369894412, confidence: 0.8994492066282034, channel: .green),
            CRFHeartRateBPMSample(timestamp: 51.3231009993, bpm: 67.9584846410716, confidence: 0.9115548708180149, channel: .green),
            CRFHeartRateBPMSample(timestamp: 52.3237071663, bpm: 67.95848426692528, confidence: 0.9090951134939645, channel: .green),
            CRFHeartRateBPMSample(timestamp: 53.3243131243, bpm: 67.95848426692528, confidence: 0.9016664647138142, channel: .green),
            CRFHeartRateBPMSample(timestamp: 54.3249191243, bpm: 67.95848426692525, confidence: 0.8985739988740599, channel: .red),
            CRFHeartRateBPMSample(timestamp: 55.3255251663, bpm: 67.95848370345189, confidence: 0.9095022749620564, channel: .green),
            CRFHeartRateBPMSample(timestamp: 56.3261310413, bpm: 67.95848483039869, confidence: 0.8958170645972368, channel: .green),
            CRFHeartRateBPMSample(timestamp: 57.3267370413, bpm: 67.95848445174457, confidence: 0.8956174838084865, channel: .green),
            CRFHeartRateBPMSample(timestamp: 58.3273430413, bpm: 67.95848464107164, confidence: 0.8986418987043391, channel: .green),
            CRFHeartRateBPMSample(timestamp: 59.3279491243, bpm: 67.95848407759824, confidence: 0.8896016693876465, channel: .green),
            CRFHeartRateBPMSample(timestamp: 60.3285551243, bpm: 67.9584840775982, confidence: 0.8895332581586164, channel: .green),
            CRFHeartRateBPMSample(timestamp: 61.3291610833, bpm: 67.9584836989441, confidence: 0.8901171128383659, channel: .red)]
        
        let expect = expectation(description: "Calculate non-zero heart rate.")
        var bpm: [Double] = []
        var confidence: [Double] = []
        let processor = CRFHeartRateSampleProcessor()
        processor.callback = { (in_bpm, in_confidence) in
            bpm.append(in_bpm)
            confidence.append(in_confidence)
            if (bpm.count == expectedHRValues.count) {
                expect.fulfill()
            }
        }

        let estimatedSamplingRate = 60
        let drop = start * estimatedSamplingRate
        let samples = testHRData.hr_data.dropFirst(drop)
        samples.forEach {
            processor.processSample($0)
        }

        // Use a very long timeout. We can optimize how long this takes later. syoung 04/16/2019
        waitForExpectations(timeout: 20) { (err) in
            XCTAssertNil(err)
            print(String(describing: err))
        }

        XCTAssertEqual(bpm.count, expectedHRValues.count)
        for ii in 0..<min(bpm.count, expectedHRValues.count) {
            let expectedBPM = expectedHRValues[ii].bpm
            XCTAssertEqual(bpm[ii], expectedBPM, accuracy: 0.1, "\(ii)")
            let expectedConfidence = expectedHRValues[ii].confidence
            XCTAssertEqual(confidence[ii], expectedConfidence, accuracy: 0.1, "\(ii)")
        }
        
         // Uncomment to update the values used for testing Android
//        processor.bpmSamples.forEach {
//            print("HeartRateBPM(\($0.timestamp!),\($0.bpm),\($0.confidence),\"\($0.channel!.rawValue)\"),")
//        }
        
        // Uncomment to update the values used for testing iOS
//        processor.bpmSamples.forEach {
//            print("CRFHeartRateBPMSample(timestamp: \($0.timestamp!), bpm: \($0.bpm), confidence: \($0.confidence), channel: .\($0.channel!.rawValue)),")
//        }
    }
    
    func testMeanOrderValue() {
        let processor = CRFHeartRateSampleProcessor()
        XCTAssertEqual(15, processor.meanFilterOrder(for: 12))
        XCTAssertEqual(15, processor.meanFilterOrder(for: 15))
        XCTAssertEqual(19, processor.meanFilterOrder(for: 16))
        XCTAssertEqual(19, processor.meanFilterOrder(for: 18))
        XCTAssertEqual(33, processor.meanFilterOrder(for: 19))
        XCTAssertEqual(33, processor.meanFilterOrder(for: 32))
        XCTAssertEqual(65, processor.meanFilterOrder(for: 33))
        XCTAssertEqual(65, processor.meanFilterOrder(for: 60))
    }
}
    
let testData: ProcessorTestData = {
    do {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "io_examples", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let params = try decoder.decode(ProcessorTestData.self, from: data)
        return params
    }
    catch let err {
        fatalError("Cannot decode test data. \(err)")
    }
}()

let testHRData: HRProcessorTestData = {
    do {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "io_examples_whole", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let params = try decoder.decode(HRProcessorTestData.self, from: data)
        return params
    }
    catch let err {
        fatalError("Cannot decode test data. \(err)")
    }
}()

let testHRData12hz: HRProcessorTestData = {
    do {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "io_examples_whole_12hz", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let params = try decoder.decode(HRProcessorTestData.self, from: data)
        return params
    }
    catch let err {
        fatalError("Cannot decode test data. \(err)")
    }
}()

let testEarlierPeaksExample: TestHRPeaks = {
    do {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "io_example_earlier_peak", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let params = try decoder.decode(TestHRPeaks.self, from: data)
        return params
    }
    catch let err {
        fatalError("Cannot decode test data. \(err)")
    }
}()

let testLaterPeaksExample: TestHRPeaks = {
    do {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "io_example_later_peak", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let params = try decoder.decode(TestHRPeaks.self, from: data)
        return params
    }
    catch let err {
        fatalError("Cannot decode test data. \(err)")
    }
}()


struct ProcessorTestData : Codable {
    
    let input : [Double]
    let lowpass : [Double]
    let highpass : [Double]
    let mcfilter : [Double]
    let acf : [Double]
    let b_lowpass : [Double]
    let a_lowpass : [Double]
    let b_highpass : [Double]
    let a_highpass : [Double]
    let mean_filter_order : [Int]
    let sampling_rate_round : [Int]
    let sampling_rate: [Double]
    let max_hr: [Int]
    let min_hr: [Int]
    let max_lag: [Int]
    let min_lag: [Int]
    
    var samplingRate: Double {
        return sampling_rate.first!
    }
    
    var maxLag: Int {
        return max_lag.first!
    }
    
    var minLag: Int {
        return min_lag.first!
    }
    
    var roundedSamplingRate: Int {
        return sampling_rate_round.first!
    }
}

struct HRProcessorTestData : Decodable {
    
    let hr_data : [TestPixelSample]
    let hr_data_chunks : [String : [[Double]]]
    let hr_estimates : [String : [HRTuple]]
    
    // The matrix for this is defined very oddly. It's actually a mapping of the index of each element.
    func hrInputChunk(for key: ChannelKeys) -> [[Double]] {
        let vector = hr_data_chunks[key.stringValue]!
        return flip(vector)
    }
    
    func flip(_ vector: [[Double]]) -> [[Double]] {
        let first = vector[0]
        let ret = Array(0..<first.count).map { (nn) -> [Double] in
            return Array(0..<vector.count).map { (mm) -> Double in
                return vector[mm][nn]
            }
        }
        return ret
    }
}

struct TestHRPeaks : Decodable {
    let x: [Double]
    let y: [[[Double]]]
    let xacf: [Double]
    let hr_initial_guess: [Double]
    let est_hr: [Double?]
    let est_conf: [Double?]
    let aliased_peak: AliasedPeak
    let sampling_rate: [Double]
    let min_lag: [Int]
    let max_lag: [Int]
    let y_min: [Double]
    let y_max: [Double]
    let x_min: [Double]
    let x_max: [Double]
    
    struct AliasedPeak : Decodable {
        private enum CodingKeys : String, CodingKey {
            case Npeaks, earlier_peak, later_peak
        }
        
        let nPeaks : Int
        let earlierPeaks : [Int]
        let laterPeaks : [Int]
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let Npeaks = try container.decode([Int].self, forKey: .Npeaks)
            self.nPeaks = Npeaks.first!
            let earlierContainer = try container.nestedUnkeyedContainer(forKey: .earlier_peak)
            self.earlierPeaks = try AliasedPeak.decodePeaks(from: earlierContainer)
            let laterContainer = try container.nestedUnkeyedContainer(forKey: .later_peak)
            self.laterPeaks = try AliasedPeak.decodePeaks(from: laterContainer)
        }
        
        static func decodePeaks(from unkeyedContainer: UnkeyedDecodingContainer) throws -> [Int] {
            var peaks = [Int]()
            var container = unkeyedContainer
            while container.isAtEnd == false {
                if let value = try? container.decode(Int.self) {
                    peaks.append(value)
                } else if let _ = try? container.decode(String.self) {
                } else {
                    let _ = try container.decodeNil()
                }
            }
            return peaks
        }
        
    }
    
    var generatedSamplingRate : Double {
        return sampling_rate.first!
    }
    
    var initialGuess : Double {
        return hr_initial_guess.first!
    }
    
    var estimatedHR : Double {
        return est_hr.first! ?? 0
    }
    
    var estimatedConfidence : Double {
        return est_conf.first! ?? 0
    }
    
    var y_output: [Double] {
        return y.map { $0.first!.first! }
    }
    
    var yMin : Double {
        return y_min.first!
    }
    
    var yMax : Double {
        return y_max.first!
    }
    
    var xMin : Double {
        return x_min.first!
    }
    
    var xMax : Double {
        return x_max.first!
    }
    
    var minLag : Int {
        return min_lag.first!
    }
    
    var maxLag : Int {
        return max_lag.first!
    }
}

struct TestPixelSample : Codable, PixelSample {
    private enum CodingKeys : String, CodingKey {
        case presentationTimestamp = "t", _red = "red", _green = "green", _blue = "blue"
    }
    
    let presentationTimestamp: Double
    let _red: Double?
    let _green: Double?
    let _blue: Double?
    
    var red: Double {
        return _red ?? 0
    }
    
    var green: Double {
        return _green ?? 0
    }
    
    var blue: Double {
        return _blue ?? 0
    }
    
    var isCoveringLens: Bool {
        return _red != nil && _green != nil && _blue != nil
    }
}

struct HRTuple : Codable {
    let hr: Double?
    let confidence: Double?
}

enum ChannelKeys : String, CodingKey, CaseIterable {
    case red, green, blue
}

