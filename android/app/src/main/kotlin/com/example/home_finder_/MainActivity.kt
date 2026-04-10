package com.example.home_finder_

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val callChannelName = "home_finder/call"
	private val emailChannelName = "home_finder/email"
	private val mapChannelName = "home_finder/map"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"call" -> {
						val phoneNumber = call.argument<String>("phoneNumber")?.trim()
						if (phoneNumber.isNullOrEmpty()) {
							result.error("INVALID_ARGUMENT", "Phone number is empty", null)
							return@setMethodCallHandler
						}

						val intent = Intent(Intent.ACTION_DIAL).apply {
							data = Uri.parse("tel:$phoneNumber")
							addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						}

						try {
							startActivity(intent)
							result.success(null)
						} catch (e: Exception) {
							result.error("DIAL_FAILED", e.localizedMessage, null)
						}
					}

					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, emailChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"email" -> {
						val emailAddress = call.argument<String>("emailAddress")?.trim()
						if (emailAddress.isNullOrEmpty()) {
							result.error("INVALID_ARGUMENT", "Email address is empty", null)
							return@setMethodCallHandler
						}

						val intent = Intent(Intent.ACTION_SENDTO).apply {
							data = Uri.parse("mailto:$emailAddress")
							addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						}

						try {
							startActivity(intent)
							result.success(null)
						} catch (e: Exception) {
							result.error("EMAIL_FAILED", e.localizedMessage, null)
						}
					}

					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mapChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"map" -> {
						val geoLocation = call.argument<String>("geoLocation")?.trim()
						if (geoLocation.isNullOrEmpty()) {
							result.error("INVALID_ARGUMENT", "Geo location is empty", null)
							return@setMethodCallHandler
						}

						val intent = Intent(Intent.ACTION_VIEW).apply {
							data = Uri.parse("geo:0,0?q=${Uri.encode(geoLocation)}")
							addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						}

						try {
							startActivity(intent)
							result.success(null)
						} catch (e: Exception) {
							result.error("MAP_FAILED", e.localizedMessage, null)
						}
					}

					else -> result.notImplemented()
				}
			}
	}
}
