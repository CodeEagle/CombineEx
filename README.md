# CombineEx

 Improving Combine by adding `All`, `Any`, `Await`, `Race` operators, similar to [`Promises`](https://github.com/google/promises)
 
Thread safe for all adding operators

Installation
---
Swift Package Manager
```
.package(url: "https://github.com/CodeEagle/CombineEx.it", from: "1.0.0")
```

`All`
---
```swift
// same type
all(publisher...)
all([publisher])

// different type
all(a, b)
// max to four different pulisher
all(a, b, c, d)
```

`Any`
---
```swift
// same type
any(publisher...)
any([publisher])

// different type
any(a, b)
// max to four different pulisher
any(a, b, c, d)
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
race(publisher...)
race([publisher])
```
