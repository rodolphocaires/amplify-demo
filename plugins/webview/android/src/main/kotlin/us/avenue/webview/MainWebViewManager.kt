package us.avenue.webview

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class MainWebViewManager(var activity: Activity?,
                         val context: Context?,
                         val messenger: BinaryMessenger,
                         val containerView: View?): PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    private var mFilePathCallback: ValueCallback<Array<Uri>>? = null
    private var mCameraPhotoPath: String? = null
    private var INPUT_FILE_REQUEST_CODE = 1

    var resultHandler:ResultHandler

    init {
        resultHandler = ResultHandler()
    }

    override fun create(context: Context?, id: Int, args: Any?): PlatformView {
        return createWebView(id)
    }

    fun createWebView(id: Int): PlatformView {
        val webView = MainWebPlatformView(context, activity,containerView, messenger, "webview$id")
        webView.webView.webChromeClient = object: WebChromeClient() {
            @TargetApi(Build.VERSION_CODES.LOLLIPOP)
            override fun onShowFileChooser(webView: WebView?,
                                           filePathCallback: ValueCallback<Array<Uri>>?,
                                           fileChooserParams: FileChooserParams?): Boolean {

                mFilePathCallback?.onReceiveValue(null);

                mFilePathCallback = filePathCallback;

                val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                activity?.let {
                    if (takePictureIntent.resolveActivity(it.packageManager) != null) {
                        var photoFile: File? = null;
                        try {
                            photoFile = createImageFile();
                            takePictureIntent.putExtra("PhotoPath", mCameraPhotoPath);
                        } catch (ex: IOException) {
                            Log.e("MainWebViewManager", "Unable to create Image File", ex);
                        }

                        if (photoFile != null) {
                            mCameraPhotoPath = "file:" + photoFile.absolutePath;
                            takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(photoFile));
                        }
                    }
                }

                val contentSelectionIntent = Intent(Intent.ACTION_GET_CONTENT);
                contentSelectionIntent.addCategory(Intent.CATEGORY_OPENABLE);
                contentSelectionIntent.setType("image/*");

                val intentArray = arrayOf(takePictureIntent)

                val chooserIntent = Intent(Intent.ACTION_CHOOSER);
                chooserIntent.putExtra(Intent.EXTRA_INTENT, contentSelectionIntent);
                chooserIntent.putExtra(Intent.EXTRA_TITLE, "Image Chooser");
                chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, intentArray);

                activity?.startActivityForResult(chooserIntent, INPUT_FILE_REQUEST_CODE);

                return true
            }

            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                webView.onProgressChanged(newProgress /100.0 )
            }
        }

        return webView
    }

    @SuppressLint("SimpleDateFormat")
    @Throws(IOException::class)
    private fun createImageFile(): File {

        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss").format(Date())
        val imageFileName = "JPEG_" + timeStamp + "_"

        return File.createTempFile(
                imageFileName,
                ".jpg",
                context?.filesDir
        )
    }

    inner class ResultHandler {
        fun handleResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
            var handled = false

            if (requestCode != INPUT_FILE_REQUEST_CODE || mFilePathCallback == null) {
                return handled
            }

            var results: Array<Uri>? = null

            if (resultCode == Activity.RESULT_OK) {
                if (intent == null) {
                    if (mCameraPhotoPath != null) {
                        results = arrayOf(Uri.parse(mCameraPhotoPath))
                    }
                } else {
                    val dataString = intent.dataString
                    if (dataString != null) {
                        results = arrayOf(Uri.parse(dataString))
                    }
                }
                mFilePathCallback?.onReceiveValue(results)
                mFilePathCallback = null
                handled =  true
            }

            return handled
        }
    }

}