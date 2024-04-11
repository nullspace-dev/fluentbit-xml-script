# fluentbit-xml-script

This is a way to use teh script.lua file in fluent bit to parse windows XML files into JSON so your SIEM or log aggreagation can easily grok it.

It's far from complete but this shoudl cover 95% of the logs that come out of windows.


Note:
All files in the lib folder should be copied to the %FluentBit-Dir%/bin/lua folder 

the scrips.lua file should be in your %FluentBit-Dir%/conf/ folder
 
 
A profiler helper class is included as I found it very helpful on determining issues with particular logs