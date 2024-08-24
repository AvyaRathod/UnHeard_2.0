import coremltools
import tensorflow as tf

model_path = 'model_checkpoint.h5'

keras_model =  tf.keras.models.load_model(model_path)

model = coremltools.convert(keras_model, convert_to="mlprogram")

model.save("STT_noAug")