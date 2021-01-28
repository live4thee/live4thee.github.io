---
categories:
- programming
date: 2015-06-17T00:00:00Z
description: ""
tags:
- OData
- WebApi
- .Net
title: Another OData Pitfall
url: /2015/06/17/another-odata-pitfall/
---


今天又碰到 OData 一个坑，那就是，枚举类型在 JSON 格式中表现为字符串，
而非数值。其
[文档](http://docs.oasis-open.org/odata/odata-json-format/v4.0/errata02/os/odata-json-format-v4.0-errata02-os-complete.html#_Toc403940629)
中有如下描述：

    Values of type enumValue are represented as JSON strings using the
    enumerationMember, defined in [OData-ABNF], where available.

而我用 Json.Net 将对象序列化成 JSON 时，默认行为是将枚举类型表示为数值。
造成的问题就是，我的 `ODataActionParameters`始终拿不到客户端传来的参数。
解决的办法是，让Json.Net序列化某个枚举类型时，将其转成字符串。

比如，

    enum Gender { Male, Female }

    class Person
    {
        int Age { get; set; }
        Gender Gender { get; set; }
    }

其中，对`Person`类的`Gender`域加上如下修饰：

    [JsonConverter(typeof(StringEnumConverter))]
    public Gender Gender { get; set; }

详情可参考[StackOverflow](https://stackoverflow.com/questions/2441290/json-serialization-of-enum-as-string).
