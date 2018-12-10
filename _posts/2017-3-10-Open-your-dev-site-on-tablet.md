When doing mobile development with Vaadin, you often develop the app on your dev machine and view the page on a tablet or a phone. Yet, entering your dev machine IP into the phone browser may be tedious and error-prone. There is a way though, to enter an URL to your phone. Via a camera, as a QR Code.

Imagine having a special PopupView in your menu, which would upon clicking reveal the QR code to your machine :-)

![qrcode-popup2.png]({{ site.baseurl }}/images/qrcode-popup2.png)

With [Vaadin On Kotlin](https://github.com/mvysny/vaadin-on-kotlin) this is easy.
Just use the [QRCode Vaadin Component](https://vaadin.com/directory#!addon/qrcode)
and add the following code:

```kotlin
val hostIPAddress: String? get() {
    val iface = NetworkInterface.getNetworkInterfaces().toList().filter { it.isUp && !it.isLoopback && !it.isVirtual }.firstOrNull() ?: return null
    val address = iface.inetAddresses.toList().filterIsInstance<Inet4Address>().firstOrNull() ?: return null
    return address.hostAddress
}

fun HasComponents.qrcode(value: String, block: QRCode.()->Unit = {}) = init(QRCode()) {
    this.value = value
    block()
}
```

Then, in your UI somewhere:

```kotlin
if (hostIPAddress != null) {
    popupView("QR Code") {
        verticalLayout {
            val url = "http://${hostIPAddress}:8080/"
            label(url)
            qrcode(url) { w = 300.px; h = 300.px }
        }
  	}
}
```

And voila! Just launch the [Barcode Scanner](https://play.google.com/store/apps/details?id=com.google.zxing.client.android)
app and point your tablet or your cellphone towards your screen.
