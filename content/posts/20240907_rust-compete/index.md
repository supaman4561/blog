---
title: "【競プロ】RustのBTreeSetでlower_bound"
date: 2024-09-07T00:48:57+09:00
tags: [rust]
categories: [競プロ]
draft: true
---

## TL;DR

HashSetもあるが、BTreeSetの方が楽そう。

```
let a : BTreeSet<usize> = BTreeSet::new();
let key = 2
let it = a.range(key..).next().unwrap();
```

`upper_bound`も

```
let a : BTreeSet<usize> = BTreeSet::new();
let key = 2
let it = a.range(..key).next_back().unwrap();
```
