---
layout: post
title: What to do when Vaadin Grid behaves slowly?
---

Grid is the most complex component in Vaadin, and it's not easy to figure out
what to do when it starts behaving slow. However, here are couple of tips to try.
Try these tips out regardless of whether you're using Vaadin 8 or Vaadin 14.

## Use fixed column widths

Apparently calculating widths of dynamic columns is pretty CPU-intensive. Making
as many columns as possible having fixed width is the easiest and the most effective
solution to try.

## replace ComponentRenderers with HtmlRenderers or similar

See [Is your Grid too slow?](https://vaadin.com/blog/using-the-right-r)
for more details.

## increase row height

Higher rows -> less data visible on screen at a time -> faster rendering

## Remove unnecessary columns

Having 30+ columns in a Grid will cause the Grid's performance to degrade exponentially.

Make sure the Grid only has 30 columns or less.

## TODO more

Let me know if you find more info, and I'll add the info here.
