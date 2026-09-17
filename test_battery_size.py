from AppKit import NSFont, NSString

font = NSFont.systemFontOfSize_weight_(9, 0.3) # bold is ~0.3
s = NSString.stringWithString_("100%")
size = s.sizeWithAttributes_({ "NSFont": font })
print("Size of '100%' at 9pt bold:", size.width, size.height)

s = NSString.stringWithString_("100")
size = s.sizeWithAttributes_({ "NSFont": font })
print("Size of '100' at 9pt bold:", size.width, size.height)
