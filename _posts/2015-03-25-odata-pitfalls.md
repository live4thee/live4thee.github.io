---
layout: post
title: "OData Pitfalls"
description: "Programing WebApi with OData"
category: programming
tags: [OData, WebApi]
---
{% include JB/setup %}

I have been writing WebApi with [OData](http://www.odata.org) v4 these
days. While it is really fast, and convenient, I experienced a few
pitfalls which costs me several hours.

## URL Sensitivity

The path segment etc. are case sensitive by default. Thus, you would
probably receive an HTTP 404 when GET `~/api/customers` instead of
`~/api/Customers`.

## String Parameter Issue

Assuming that I have a bound function `GetCustomerX` for the entity
type `Customer`, and it is indexed with a string identifier.

    public IHttpActionResult GetCustomerX(string key)

When calling into this function with string `'foo'`, the parameter
`key` will be bounded to a single quoted string `'foo'`. To escape
from the single quote, you need to decorate the `key` parameter with
`FromODataUri` attribute.

    public IHttpActionResult GetCustomerX([FromODataUri] string key)

## 404 on Function Routing

This issue almost drove me crazy. I had a bound function, but always
got a 404 error, by all means. And it turns out that, I missed the
following configuration in my `web.config`.

    <system.webServer>
      <modules runAllManagedModulesForAllRequests="true" />
    </system.webServer>

I found this solution from
[stackoverflow](https://stackoverflow.com/questions/25311955/web-api-2-2-odata-v4-function-routing).

## Further Readings

The issues above in fact have **all** been captured in
[OData Web API document](http://odata.github.io/WebApi/). Make sure
you read it before building WebApi with OData in production code.
