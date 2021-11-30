package com.example.flutterpytorch;

import com.example.flutterpytorch.Constants;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Map;
import org.pytorch.IValue;
import org.pytorch.Module;
import org.pytorch.Tensor;
import org.pytorch.torchvision.TensorImageUtils;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "samples.flutter.dev/battery",
                        PYTORCH_CHANNEL = "com.pytorch_channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            PYTORCH_CHANNEL
        ).setMethodCallHandler(
            (req,res) -> {
                switch(req.method){
                    case "predict_image":
                        Bitmap bitmap = null;
                        Module module = null;

                        try {
                            String absPath = req.argument("model_path");
                            int boffset = req.argument("data_offset"),
                                blength = req.argument("data_length");
                            byte[] byteStream = req.argument("image_data");
                            bitmap = BitmapFactory.decodeByteArray(byteStream,boffset,blength);

                            Log.i("Pytorch: Main Activity",absPath);
                            module = Module.load(absPath);
                        } catch (Exception e) {
                            Log.e("Pytorch: Main Activity","Error reading",e);
                            finish();
                        }

                        Tensor inputTensor = TensorImageUtils.bitmapToFloat32Tensor(
                            bitmap,
                            TensorImageUtils.TORCHVISION_NORM_MEAN_RGB,
                            TensorImageUtils.TORCHVISION_NORM_STD_RGB
                        );

                        final Tensor otensor = module.forward(IValue.from(inputTensor)).toTensor();

                        float[] scores = otensor.getDataAsFloatArray();

                        float maxScore = -Float.MAX_VALUE;
                        int maxScoreIdx = -1;

                        for (int i=0;i<scores.length;i++){
                            if (scores[i] > maxScore){
                                maxScore = scores[i];
                                maxScoreIdx = i;
                            }
                        }

                        String className = Constants.IMAGENET_CLASSES[maxScoreIdx];
                        res.success(className);
                        break;

                    default:
                        res.notImplemented();
                        break;
                        
                }
            }
        );

    }

}
