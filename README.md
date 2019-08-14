# CombineEx

 Improving Combine by adding `All`, `Any`, `Await`, `Race` operators, similar to [`Promises`](https://github.com/google/promises)
 
Thread safe for all adding operators

Installation
---
Swift Package Manager
```
.package(url: "https://github.com/CodeEagle/CombineEx.git", from: "1.0.0")
```

Usage
---
Remember to keep the `AnyCancelabel` in your own

`All`
---
```swift
// same type
let token = all(publisher...)
let token = all([publisher])

// different type
let token = all(a, b)
// up to four different pulisher
let token = all(a, b, c, d)
```

`Any`
---
```swift
// same type
let token = any(publisher...)
let token = any([publisher])

// different type
let token = any(a, b)
// up to four different pulisher
let token = any(a, b, c, d)
```

`Await`
---
```swift
_ = try publisher.await()
```

`Race`
---
```swift
// only support same type racing
let token = race(publisher...)
let token = race([publisher])
```
