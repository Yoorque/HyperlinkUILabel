//
//  HyperlinkUILabel.swift
//
//  Created by Dusan Juranovic on 30/10/2020.
//  Copyright © 2020 Dusan Juranovic. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
@IBDesignable public class HyperlinkUILabel: UILabel {
	@IBInspectable public var shouldUnderline:Bool = true {
		didSet {
			setProperties()
		}
	}
	@IBInspectable public var hyperlinkColor:UIColor? {
		didSet {
			setProperties()
		}
	}
	@IBInspectable public var hyperlinkedText:String? {
		didSet {
			setProperties()
		}
	}
    
	override public init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}
	
	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		initialize()
	}
	
	private func initialize() {
		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openLink)))
		self.isUserInteractionEnabled = true
		self.lineBreakMode = .byWordWrapping
		self.shouldUnderline = true
		self.hyperlinkedText = ""
		self.hyperlinkColor = UIColor.blue
	}
	
	@objc func setProperties() {
		self.attributedText = hyperlinkify(hyperlinkedText ?? "", color: hyperlinkColor ?? UIColor.blue, font: self.font, shouldUnderline:shouldUnderline)
	}
	@available(iOS 10.0, *)
	@objc private func openLink(_ recognizer: UITapGestureRecognizer) {
		guard let text = self.attributedText?.string else {return}
		let urls = markURLs(text)
		for url in urls {
			if let ranges = text.ranges(of: url) {
				for range in ranges {
					if recognizer.didTapAttributedTextInLabel(label: self, inRange: NSRange(range, in: text)) {
						if UIApplication.shared.canOpenURL(URL(string: url)!) {
							UIApplication.shared.open(URL(string: url)!, options: [:]) { (completed) in
								if completed {
									print("Link opened: \(url)")
								}
							}
						} else {
							let validUrl = "https://".appending(url)
							UIApplication.shared.open(URL(string: validUrl)!, options: [:]) { (completed) in
								if completed {
									print("Link corrected and opened: \(url)")
								}
							}
						}
					}
				}
			}
		}
	}
	
	private func markURLs(_ text:String?) -> [String] {
		let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
		guard let text = text else {return []}
		let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
		var urls = [String]()
		for match in matches {
			guard let range = Range(match.range, in: text) else { continue }
			urls.append(String(text[range]))
		}
		return urls
	}
	
	private func hyperlinkify(_ text: String?, color:UIColor?, font:UIFont?, shouldUnderline:Bool) -> NSAttributedString {
		guard let text = text else {return NSAttributedString()}
		let urls = self.markURLs(text)
		let attributedString = NSMutableAttributedString(string: text)
		
		for url in urls {
			//get range of url
			if let foundRanges = attributedString.string.ranges(of: url) {
				for range in foundRanges {
					//add hyperlink attributes to string in range
					attributedString.addAttribute(NSAttributedString.Key.underlineColor, value: color ?? UIColor.blue, range: NSRange(range, in: url))
					attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color ?? UIColor.blue, range: NSRange(range, in: url))
					attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: shouldUnderline ? NSUnderlineStyle.single.rawValue : NSUnderlineStyle(), range: NSRange(range, in: url))
					attributedString.addAttribute(NSAttributedString.Key.font, value: font ?? UIFont.systemFont(ofSize: 17), range: NSRange(range, in: url))
				}
			}
		}
		return attributedString
	}
	
	public override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		
	}
}

private extension String {
	func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>]? {
		var ranges: [Range<Index>] = []
		while let range = range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
			ranges.append(range)
		}
		return ranges
	}
}

@available(iOS 10.0, *)
private extension UITapGestureRecognizer {
	func didTapAttributedTextInLabel(label: HyperlinkUILabel, inRange targetRange: NSRange) -> Bool {
		guard let attrString = label.attributedText else {
			return false
		}
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		let font = label.font ?? UIFont.systemFont(ofSize: 17)
		mutableAttrString.addAttributes([NSAttributedString.Key.font: font], range: NSRange(location: 0, length: attrString.string.count))

		let layoutManager = NSLayoutManager()
		let textContainer = NSTextContainer(size: .zero)
		let textStorage = NSTextStorage(attributedString: mutableAttrString)

		layoutManager.addTextContainer(textContainer)
		textStorage.addLayoutManager(layoutManager)

		textContainer.lineFragmentPadding = 0
		textContainer.lineBreakMode = label.lineBreakMode
		textContainer.maximumNumberOfLines = label.numberOfLines
		let labelSize = label.bounds.size
		textContainer.size = labelSize

		let locationOfTouchInLabel = self.location(in: label)
		let textBoundingBox = layoutManager.usedRect(for: textContainer)
		let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
		let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
		let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
		return NSLocationInRange(indexOfCharacter, targetRange)
	}
}

