---
categories:
- programming
date: 2015-04-13T00:00:00Z
description: A show case of the LINQ in C#
tags:
- .Net
title: A Show case of LINQ
url: /2015/04/13/a-show-case-of-linq/
---


As a long-time Linux programmer, I barely got a laughter from my
wife, when offered a few praises to the productivity of C#.  It is
interesting - we are apt to *believe* that what we've already known
are the best, even we don't have any convincing *evidence*. We are
pretty much biased.

I do like the feature Language-Integrated Query, aka. LINQ, introduced
since .Net 3.5. And here is a show case. I have a collection of
key-value pairs representing consumed bandwidth for each time slot,
say, five minutes.  Now, how can I transform the collection to another
collection with time slot set to one day?

    var result = details
        .GroupBy(r => r.Key.Date)
        .Select(g => new KeyValuePair<DateTime, double>
                           (g.Key.Date, g.Sum(x => x.Value)));

Descriptive. Pretty simple.
