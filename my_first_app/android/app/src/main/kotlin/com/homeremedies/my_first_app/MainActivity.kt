package com.homeremedies.my_first_app

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.media.AudioTrack
import android.media.AudioManager
import android.media.AudioAttributes
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.shabd.edge.services.VoiceAI
import org.shabd.edge.tts.interfaces.ITTSService
import org.shabd.edge.interfaces.ISTTService
import org.shabd.edge.interfaces.IMTService

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.homeremedies/shabd_sdk"
    private var voiceAI: VoiceAI? = null
    private var methodChannel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Audio recording for STT
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // ──────────────────────────────────────────────
                // INITIALIZE TTS
                // ──────────────────────────────────────────────
                "initializeTTS" -> {
                    try {
                        val licenseKey = call.argument<String>("licenseKey") ?: ""
                        val language = call.argument<String>("language") ?: "hi"
                        val gender = call.argument<String>("gender") ?: "female"
                        val speed = call.argument<Double>("speed")?.toFloat() ?: 1.4f

                        val basePath = context.filesDir.absolutePath

                        voiceAI = VoiceAI()
                        voiceAI?.setAndroidContext(context)
                        voiceAI?.initializeTTS(basePath, licenseKey, language, gender, speed)

                        result.success(mapOf("success" to true, "message" to "TTS initialized"))
                    } catch (e: Exception) {
                        result.error("TTS_INIT_ERROR", e.message, null)
                    }
                }

                // ──────────────────────────────────────────────
                // INITIALIZE STT
                // ──────────────────────────────────────────────
                "initializeSTT" -> {
                    try {
                        val licenseKey = call.argument<String>("licenseKey") ?: ""
                        val language = call.argument<String>("language") ?: "hi"
                        val sampleRate = call.argument<Int>("sampleRate") ?: 16000

                        val basePath = context.filesDir.absolutePath

                        voiceAI = voiceAI ?: VoiceAI()
                        voiceAI?.setAndroidContext(context)
                        voiceAI?.initializeSTT(basePath, licenseKey, language, sampleRate)

                        result.success(mapOf("success" to true, "message" to "STT initialized"))
                    } catch (e: Exception) {
                        result.error("STT_INIT_ERROR", e.message, null)
                    }
                }

                // ──────────────────────────────────────────────
                // INITIALIZE MT (Machine Translation - Cloud)
                // ──────────────────────────────────────────────
                "initializeMT" -> {
                    try {
                        val apiKey = call.argument<String>("apiKey") ?: ""
                        val sourceLanguage = call.argument<String>("sourceLanguage") ?: "hi"
                        val targetLanguage = call.argument<String>("targetLanguage") ?: "en"

                        voiceAI = voiceAI ?: VoiceAI()
                        voiceAI?.initializeMT(apiKey, sourceLanguage, targetLanguage)

                        result.success(mapOf("success" to true, "message" to "MT initialized"))
                    } catch (e: Exception) {
                        result.error("MT_INIT_ERROR", e.message, null)
                    }
                }

                // ──────────────────────────────────────────────
                // TTS: Synthesize Speech
                // ──────────────────────────────────────────────
                "synthesizeSpeech" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (voiceAI == null) {
                        result.error("NOT_INITIALIZED", "TTS not initialized. Call initializeTTS first.", null)
                        return@setMethodCallHandler
                    }

                    voiceAI?.synthesizeSpeech(text, object : ITTSService {
                        override fun onAudioReady(audioData: ByteArray) {
                            mainHandler.post {
                                if (audioData.isNotEmpty()) {
                                    // Play the audio
                                    playAudio(audioData)
                                    result.success(mapOf("success" to true, "audioLength" to audioData.size))
                                } else {
                                    result.success(mapOf("success" to true, "audioLength" to 0))
                                }
                            }
                        }

                        override fun onError(t: Throwable) {
                            mainHandler.post {
                                result.error("TTS_ERROR", t.message ?: "Unknown TTS error", null)
                            }
                        }
                    })
                }

                // ──────────────────────────────────────────────
                // STT: Start Recording & Transcribing
                // ──────────────────────────────────────────────
                "startListening" -> {
                    if (voiceAI == null) {
                        result.error("NOT_INITIALIZED", "STT not initialized. Call initializeSTT first.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        startRecording()
                        result.success(mapOf("success" to true, "message" to "Listening started"))
                    } catch (e: Exception) {
                        result.error("STT_START_ERROR", e.message, null)
                    }
                }

                // ──────────────────────────────────────────────
                // STT: Stop Recording
                // ──────────────────────────────────────────────
                "stopListening" -> {
                    try {
                        stopRecording()
                        result.success(mapOf("success" to true, "message" to "Listening stopped"))
                    } catch (e: Exception) {
                        result.error("STT_STOP_ERROR", e.message, null)
                    }
                }

                // ──────────────────────────────────────────────
                // MT: Translate Text
                // ──────────────────────────────────────────────
                "translate" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (voiceAI == null) {
                        result.error("NOT_INITIALIZED", "MT not initialized. Call initializeMT first.", null)
                        return@setMethodCallHandler
                    }

                    voiceAI?.translate(text, object : IMTService {
                        override fun onResult(translatedText: String?) {
                            mainHandler.post {
                                result.success(mapOf(
                                    "success" to true,
                                    "translatedText" to (translatedText ?: "")
                                ))
                            }
                        }

                        override fun onError(e: Exception?) {
                            mainHandler.post {
                                result.error("MT_ERROR", e?.message ?: "Unknown translation error", null)
                            }
                        }
                    })
                }

                // ──────────────────────────────────────────────
                // Release SDK resources
                // ──────────────────────────────────────────────
                "release" -> {
                    try {
                        stopRecording()
                        voiceAI?.release()
                        voiceAI = null
                        result.success(mapOf("success" to true, "message" to "SDK released"))
                    } catch (e: Exception) {
                        result.error("RELEASE_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // ──────────────────────────────────────────────
    // Audio Recording for STT
    // ──────────────────────────────────────────────
    private fun startRecording() {
        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioEncoding = AudioFormat.ENCODING_PCM_FLOAT
        val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioEncoding)

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            channelConfig,
            audioEncoding,
            bufferSize
        )

        audioRecord?.startRecording()
        isRecording = true

        recordingThread = Thread {
            val floatBuffer = FloatArray(bufferSize / 4)
            while (isRecording) {
                val readCount = audioRecord?.read(floatBuffer, 0, floatBuffer.size, AudioRecord.READ_BLOCKING) ?: 0
                if (readCount > 0) {
                    val chunk = floatBuffer.copyOf(readCount)
                    voiceAI?.transcribe(chunk, object : ISTTService {
                        override fun onPartialResult(text: String?) {
                            mainHandler.post {
                                methodChannel?.invokeMethod("onPartialResult", mapOf("text" to (text ?: "")))
                            }
                        }

                        override fun onFinalResult(text: String?, segmentIndex: Int) {
                            mainHandler.post {
                                methodChannel?.invokeMethod("onFinalResult", mapOf(
                                    "text" to (text ?: ""),
                                    "segmentIndex" to segmentIndex
                                ))
                            }
                        }

                        override fun onError(e: Exception?) {
                            mainHandler.post {
                                methodChannel?.invokeMethod("onSTTError", mapOf("error" to (e?.message ?: "Unknown error")))
                            }
                        }
                    })
                }
            }
        }
        recordingThread?.start()
    }

    private fun stopRecording() {
        isRecording = false
        recordingThread?.join(2000)
        recordingThread = null
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }

    // ──────────────────────────────────────────────
    // Audio Playback for TTS
    // ──────────────────────────────────────────────
    private fun playAudio(audioData: ByteArray) {
        Thread {
            try {
                val sampleRate = 22050
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()

                val audioFormat = AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()

                val audioTrack = AudioTrack(
                    audioAttributes,
                    audioFormat,
                    audioData.size,
                    AudioTrack.MODE_STATIC,
                    AudioManager.AUDIO_SESSION_ID_GENERATE
                )

                audioTrack.write(audioData, 0, audioData.size)
                audioTrack.play()

                // Wait for playback to complete
                Thread.sleep((audioData.size * 1000L / (sampleRate * 2)))
                audioTrack.stop()
                audioTrack.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()
    }

    override fun onDestroy() {
        stopRecording()
        voiceAI?.release()
        super.onDestroy()
    }
}
