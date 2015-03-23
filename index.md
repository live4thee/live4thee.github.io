---
layout: page
title: live4thee
tagline: Something like a blog
---
{% include JB/setup %}

For the last decade, I have been writing blogs, frequently or
occasionally. To me, writing is remembering, is to keep a record of my
ideas, feelings and thoughts. I would like to keep the habit of
reading and writing as a lifetime endeavor.

Before switching to [GitHub](https://pages.github.com/), I was writing
at [colorfulwe](http://live4thee.colorfulwe.com), a *WordPress* site
maintained by my friend [Yechun](http://yechun.colorfulwe.com/). I
have been using it 5 years since moving from
[Blogger](http://live4thee.blogspot.com/). Thanks a lot to Yechun!
Almost every post I have written was also formatted in a local LaTeX
file, so that I can easily compile it into a PDF book.  Switching to
GitHub, I can handle all these things with `git`, `emacs`, `markdown`,
really convenient.

When *Bilbo Baggins* handed over the book of his adventure to *Frodo
Baggins*, I saw peace from his elderly face. As prophesied by
*Galadriel*: "Even the smallest person can change the course of the
future." We, ordinary people, at least, can live a meaningful life, if
not gorgeous. If one day, when my son grows up, and come to me for
answers, I hope that the records I have kept for years,  will help.

## Latest Posts

Here are my latest blog posts.

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

## Quotes about Remembering

* The key to immortality is first living a life worth remembering. - *Bruce Lee*
* Remembering is only a new form of suffering. - *Charles Baudelaire*
* Remembering is painful, it's difficult, but it can be inspiring and it can give wisdom. - *Paul Greengrass*
