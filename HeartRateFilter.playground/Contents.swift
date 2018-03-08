
import UIKit
import Accelerate

let fs: Float = 60                                  // frames / second
let window: Float = 10                              // seconds
let window_len: Int = Int(round(fs * window))       // number of frames in the window

/// red channel, 60fps, 10sec window
func findhr(with red:[Float]) -> [(heartRate: Float, confidence: Float)] {
    let nframes = Int(floor(Float(red.count) / (Float(window_len)/2)) - 1)
    guard nframes >= 1 else { return [] }
    var output: [(Float, Float)] = []
    for frame_no in 1...nframes {
        let lower = (1 + ((frame_no - 1) * window_len / 2)) - 1
        let upper = ((frame_no + 1) * window_len / 2) - 1
        let currframe = Array(red[lower...upper])
        output.append(camerainstahrauto(currframe))
    }
    return output
}

/// For a given window return the calculated heart rate and confidence.
func camerainstahrauto(_ input: [Float]) -> (heartRate: Float, confidence: Float) {

    // % Setting no. of samples as per a max HR of 220 BPM
    let nsamples = Int(round(60 * fs / 220))
    
    // % b1 = fir1(128,[1/30, 25/30], 'bandpass');
    let b1: [Float] = [-0.000506610984132016,0.000281340196104213,-0.000453477478785663,0.000175433848479960,5.78571000126717e-19,-0.000200178238070410,0.000588479261901569,-0.000412615808534457,0.000832401037231464,-4.84818239396100e-19,0.000465554741153073,0.00102165166976478,-0.000118534274769341,0.00192609062899124,-2.40024436102973e-18,0.00182952606970045,0.00135480554590726,0.000748599044261129,0.00319643179850945,-2.30788276369201e-19,0.00382994518525259,0.00107470141262219,0.00233017559097417,0.00376919225339987,-8.21109764793137e-18,0.00568709829032464,-0.000418547259970266,0.00430878547299781,0.00234096774958672,-1.06597329751523e-17,0.00589948032626289,-0.00345001874823703,0.00577085280898743,-0.00228532700432350,-3.81044085438483e-18,0.00263801974428747,-0.00769131382422690,0.00531148463293734,-0.0104990208677403,1.62815935886881e-17,-0.00558417076326117,-0.0119241848598587,0.00134611898423683,-0.0212997771796790,-2.07091826506435e-17,-0.0192845505914200,-0.0139952617851127,-0.00760318790070690,-0.0320397640632609,-3.05719612807051e-18,-0.0378997870775431,-0.0106518977344771,-0.0232807805994706,-0.0382418951609459,1.64113172833343e-17,-0.0611787321852445,0.00471988055056295,-0.0517540592057603,-0.0305770938728010,3.42293636763843e-17,-0.100426633129967,0.0729786483544900,-0.170609488045242,0.125861208906484,0.800308136102957,0.125861208906484,-0.170609488045242,0.0729786483544900,-0.100426633129967,3.42293636763843e-17,-0.0305770938728010,-0.0517540592057603,0.00471988055056295,-0.0611787321852445,1.64113172833343e-17,-0.0382418951609459,-0.0232807805994706,-0.0106518977344771,-0.0378997870775431,-3.05719612807051e-18,-0.0320397640632609,-0.00760318790070690,-0.0139952617851127,-0.0192845505914200,-2.07091826506435e-17,-0.0212997771796790,0.00134611898423683,-0.0119241848598587,-0.00558417076326117,1.62815935886881e-17,-0.0104990208677403,0.00531148463293734,-0.00769131382422690,0.00263801974428747,-3.81044085438483e-18,-0.00228532700432350,0.00577085280898743,-0.00345001874823703,0.00589948032626289,-1.06597329751523e-17,0.00234096774958672,0.00430878547299781,-0.000418547259970266,0.00568709829032464,-8.21109764793137e-18,0.00376919225339987,0.00233017559097417,0.00107470141262219,0.00382994518525259,-2.30788276369201e-19,0.00319643179850945,0.000748599044261129,0.00135480554590726,0.00182952606970045,-2.40024436102973e-18,0.00192609062899124,-0.000118534274769341,0.00102165166976478,0.000465554741153073,-4.84818239396100e-19,0.000832401037231464,-0.000412615808534457,0.000588479261901569,-0.000200178238070410,5.78571000126717e-19,0.000175433848479960,-0.000453477478785663,0.000281340196104213,-0.000506610984132016]

    // Normalize the input
    let meanValue = input.mean()
    let normalizedValues = input.map { $0 - meanValue }

    //% Preprocess and find the autocorrelation function
    var x = xcorr(meanfilter(normalizedValues, 2*nsamples+1, b1))

    //% To just remove the repeated part of the autocorr function (since it is even)
    let (max_val, x_start) = x.seekMax()
    x = Array(x[x_start...])

    //% HR ranges from 40-200 BPM, so consider only that part of the autocorr
    //% function
    let lower = Int(round(60 * fs / 200))
    let upper = Int(round(60 * fs / 40))
    let (val, pos) = x.zeroReplace(lower-1, upper-1).seekMax()
    return (60 * fs / Float(pos), val / max_val)
}

/// Mean filter which emphasizes the maxima in a specified window length (n),
/// but de-emphasizes everything else in that window
func meanfilter(_ input: [Float], _ n: Int, _ b1: [Float]) -> [Float] {
    let x = conv(input, b1, .same).centerSplice(65)
    var output: [Float] = x
    for nn in ((n+1)/2)...(x.count-(n-1)/2) {
        let lower = (nn - (n-1)/2) - 1
        let upper = (nn + (n-1)/2) - 1
        let currwin = x[lower...upper].sorted()
        output[nn-1] = x[nn-1] - ((currwin.sum() - currwin.max()!) / Float(n - 1))
    }
    return output
}

/// Use `vDSP_conv()` to autocorrelate.
func xcorr(_ x: [Float]) -> [Float] {
    let filterLength = x.count
    let resultLength = x.count * 2 - 1
    let input1:[Float] = x.zeroPadBefore(count: resultLength - filterLength)
    let input2:[Float] = x.zeroPadAfter(count: resultLength - filterLength)
    var result:[Float] = Array(repeating: Float(0), count: resultLength)
    vDSP_conv(input1, 1, input2, 1, &result, 1, UInt(resultLength), UInt(filterLength))
    return result
}

/// convolution
/// https://www.mathworks.com/help/matlab/ref/conv.html#bucr92l-2
enum ConvolutionType { case full, same }
func conv(_ u: [Float], _ v:[Float], _ type: ConvolutionType = .full) -> [Float] {
    let m = u.count
    let n = v.count
    let range = Array(1...(m+n-1))
    let output: [Float] = range.map { (k) -> Float in
        var sum: Float = 0
        for j in max(1, k+1-n)...min(k, m) {
            sum += u[j-1] * v[k-j]
        }
        return sum
    }
    switch type {
    case .full:
        return output
    case .same:
        let center = Int(ceil(Float(output.count) / 2))
        let half_u = Int(floor(Float(u.count) / 2))
        let start = center - half_u
        let end = center + half_u
        return Array(output[start..<end])
    }
}

extension Sequence where Self.Element : Numeric {
    
    /// Sum the elements of the sequence.
    public func sum() -> Element {
        return self.reduce(0, +)
    }
}

extension Array where Element : BinaryFloatingPoint {
    
    /// Returns the mean value of the elements.
    public func mean() -> Element {
        return self.sum() / Element.init(self.count)
    }
    
    /// Returns the max value and index of that value.
    func seekMax() -> (value: Element, index: Int) {
        let value = self.max()!
        let index = self.index(of: value)!
        return (value, index)
    }
    
    /// Replace the elements of the array with the given number of zeros on each side.
    func zeroReplace(_ lowerBounds: Int, _ upperBounds: Int) -> [Element] {
        var y = Array(repeating: Element(0), count: lowerBounds)
        y.append(contentsOf: self[lowerBounds...upperBounds])
        y.append(contentsOf: Array(repeating: Element(0), count: self.count - upperBounds - 1))
        return y
    }
    
    /// Pad the array with zeros before the value.
    func zeroPadBefore(count: Int) -> [Element] {
        var output = Array(repeating: Element(0), count: count)
        output.append(contentsOf: self)
        return output
    }
    
    /// Pad the array with zeros after the value.
    func zeroPadAfter(count: Int) -> [Element] {
        var output = self
        output.append(contentsOf: Array(repeating: Element(0), count: count))
        return output
    }
    
    /// Return the center of the range minus the ends to endCount.
    func centerSplice(_ endCount: Int) -> [Element] {
        return Array(self[(endCount-1)..<(self.count-endCount)])
    }
}
