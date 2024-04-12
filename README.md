# fluentbit-xml-script

This is a way to use the script.lua file in fluent bit to parse windows Events (tested) or other XML based logs into JSON so your SIEM or log aggreagation can easily grok it.

It's far from complete but this should cover 95% of the logs that come out of windows.


Note:
All files in the lib folder **need** to be be copied to the %FluentBit-Dir%/bin/lua folder or it will not function.

the scrips.lua file should be in your %FluentBit-Dir%/conf/ folder. If you already have a scripts file there with code you'll need to look at merging the code.
 
 
A profiler helper class is included in the lib folder as I found it very helpful on determining issues with particular logs, it's not imported to the scipts file but easily added at the top if want to use it. 

