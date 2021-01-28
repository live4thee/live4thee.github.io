---
categories:
- work
date: 2015-03-24T00:00:00Z
description: ""
tags:
- .Net
- Unity
- DLL
title: Some Frustration
url: /2015/03/24/some-frustration/
---


I had some frustration these days. Two programming issues consumed
more than three work days.

The first one is related with DLL versions. One of my VS 2012 project
is created by VS 2013, but unfortunately they have different SDK
versions. And, what is worse - our production code does not use
[NuGet](https://www.nuget.org/) to resolve dependencies. They are done
manually. It is a huge pain for VS novices like me.

The second, comes from the
[Unity](https://msdn.microsoft.com/en-us/library/ff647202.aspx). I was
stuck in resolving a system class using *Unity*. And, after reading
documents, I found that it is because my configuration file missing
the settings to refer to the assembly containing the system class.

Getting started with C# is fast, but to reach proficiency, we really
need to know the hows and whys behind the frameworks.
