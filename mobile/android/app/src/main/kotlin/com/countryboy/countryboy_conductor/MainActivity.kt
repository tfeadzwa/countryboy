package com.countryboy.countryboy_conductor

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
  companion object {
    private const val CHANNEL = "countryboy/printer_identity"
    private const val TAG = "PrinterIdentity"
    private val SPP_UUID: UUID =
      UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "probeSerial" -> {
            val mac = call.argument<String>("mac")
            if (mac.isNullOrBlank()) {
              result.error("bad_args", "mac is required", null)
              return@setMethodCallHandler
            }
            thread {
              try {
                val info = probePrinterIdentity(mac)
                runOnUiThread { result.success(info) }
              } catch (e: Exception) {
                Log.w(TAG, "probe failed: ${e.message}")
                runOnUiThread {
                  result.success(
                    mapOf(
                      "serial" to null,
                      "model" to null,
                      "manufacturer" to null,
                      "error" to (e.message ?: "probe failed"),
                    ),
                  )
                }
              }
            }
          }
          else -> result.notImplemented()
        }
      }
  }

  /**
   * Best-effort ESC/POS GS I queries (printer ID / serial).
   * Many cheap Bluetooth modules ignore these; failures are expected.
   */
  private fun probePrinterIdentity(mac: String): Map<String, String?> {
    val adapter = BluetoothAdapter.getDefaultAdapter()
      ?: return mapOf("serial" to null, "model" to null, "manufacturer" to null, "error" to "no_adapter")

    var socket: BluetoothSocket? = null
    try {
      val device = adapter.getRemoteDevice(mac)
      adapter.cancelDiscovery()
      socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
      socket.connect()

      val output: OutputStream = socket.outputStream
      val input: InputStream = socket.inputStream

      // Drain any buffered noise.
      while (input.available() > 0) input.read()

      val manufacturer = queryGsI(output, input, 0x42) // GS I 66
      val model = queryGsI(output, input, 0x43) // GS I 67
      val serial = queryGsI(output, input, 0x44) // GS I 68

      return mapOf(
        "serial" to serial,
        "model" to model,
        "manufacturer" to manufacturer,
        "error" to null,
      )
    } finally {
      try {
        socket?.close()
      } catch (_: Exception) {
      }
    }
  }

  private fun queryGsI(output: OutputStream, input: InputStream, n: Int): String? {
    // GS I n  =>  1D 49 n
    output.write(byteArrayOf(0x1D, 0x49, n.toByte()))
    output.flush()
    return readAsciiResponse(input, timeoutMs = 900)
  }

  private fun readAsciiResponse(input: InputStream, timeoutMs: Long): String? {
    val deadline = System.currentTimeMillis() + timeoutMs
    val buffer = ByteArray(128)
    val collected = ArrayList<Byte>()

    while (System.currentTimeMillis() < deadline) {
      val available = input.available()
      if (available > 0) {
        val read = input.read(buffer, 0, minOf(available, buffer.size))
        if (read <= 0) break
        for (i in 0 until read) {
          val b = buffer[i]
          if (b == 0.toByte()) {
            return decodeCollected(collected)
          }
          // Keep printable ASCII + common punctuation.
          if (b in 32..126) collected.add(b)
        }
        if (collected.size >= 64) return decodeCollected(collected)
      } else {
        Thread.sleep(40)
      }
    }
    return decodeCollected(collected)
  }

  private fun decodeCollected(bytes: List<Byte>): String? {
    if (bytes.isEmpty()) return null
    val text = String(bytes.toByteArray(), Charsets.US_ASCII).trim()
    return text.ifEmpty { null }
  }
}
