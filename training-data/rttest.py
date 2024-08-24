import cv2
import numpy as np
import mediapipe as mp
import numpy as np
from collections import deque
import tensorflow as tf
from tensorflow import keras
import cv2

FRAME_LENGTH = 4032
FRAME_WIDTH = 3024

mp_hands = mp.solutions.hands.Hands(max_num_hands=2, min_detection_confidence=0.75, min_tracking_confidence=0.5)
mp_pose = mp.solutions.pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)

def swap_hands(pose_landmarks, hand1_landmarks, hand2_landmarks):
    if pose_landmarks and (hand1_landmarks or hand2_landmarks):
        # Indices in the pose landmarks for left and right wrists
        left_wrist_index = 15
        right_wrist_index = 16

        # Calculate the distance of each hand to the respective wrist
        left_wrist = pose_landmarks[left_wrist_index]
        right_wrist = pose_landmarks[right_wrist_index]

        if hand1_landmarks and not hand2_landmarks:
            hand1_distance_to_left_wrist = np.linalg.norm(np.array(left_wrist) - np.array(hand1_landmarks[0]))
            hand1_distance_to_right_wrist = np.linalg.norm(np.array(right_wrist) - np.array(hand1_landmarks[0]))
            if hand1_distance_to_right_wrist < hand1_distance_to_left_wrist:
                # The single hand detected is closer to the right wrist - swap needed
                return True
        elif hand2_landmarks and not hand1_landmarks:
            hand2_distance_to_left_wrist = np.linalg.norm(np.array(left_wrist) - np.array(hand2_landmarks[0]))
            hand2_distance_to_right_wrist = np.linalg.norm(np.array(right_wrist) - np.array(hand2_landmarks[0]))
            if hand2_distance_to_left_wrist < hand2_distance_to_right_wrist:
                # The single hand detected is closer to the left wrist - swap needed
                return True

    return False

def process_landmarks(landmarks):
    # Convert landmarks to a list of (x, y) tuples
    if landmarks:
        return [(landmark.x, landmark.y) for landmark in landmarks.landmark]
    else:
        return [(np.nan, np.nan)] * 33  # Return a list of NaN values if no landmarks are detected

def process_single_frame(frame):
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    pose_results = mp_pose.process(frame_rgb)
    hand_results = mp_hands.process(frame_rgb)

    pose_landmarks = process_landmarks(pose_results.pose_landmarks)
    hand1_landmarks = process_landmarks(hand_results.multi_hand_landmarks[0]) if hand_results.multi_hand_landmarks and len(hand_results.multi_hand_landmarks) > 0 else [(np.nan, np.nan)] * 21
    hand2_landmarks = process_landmarks(hand_results.multi_hand_landmarks[1]) if hand_results.multi_hand_landmarks and len(hand_results.multi_hand_landmarks) > 1 else [(np.nan, np.nan)] * 21

    swap = swap_hands(pose_landmarks, hand1_landmarks, hand2_landmarks)
    if swap:
        hand1_landmarks, hand2_landmarks = hand2_landmarks, hand1_landmarks

    frame_data = {
        "pose_x": [lm[0] for lm in pose_landmarks],
        "pose_y": [lm[1] for lm in pose_landmarks],
        "hand1_x": [lm[0] for lm in hand1_landmarks],
        "hand1_y": [lm[1] for lm in hand1_landmarks],
        "hand2_x": [lm[0] for lm in hand2_landmarks],
        "hand2_y": [lm[1] for lm in hand2_landmarks],
    }

    return frame_data

def generate_image(frame_data):
    FRAME_LENGTH, FRAME_WIDTH = 4032, 3024
    POINT_COLOR = (255, 0, 0)  # Red
    CONNECTION_COLOR = (0, 255, 0)  # Green
    POINT_THICKNESS = 2
    LINE_THICKNESS = 2

    # Create a blank image
    image = np.zeros((FRAME_LENGTH, FRAME_WIDTH, 3), dtype=np.uint8)

    # Function to draw landmarks and connections
    def draw_landmarks_and_connections(x_coords, y_coords, connections, image):
        for connection in connections:
            start, end = connection
            if not np.isnan(x_coords[start]) and not np.isnan(y_coords[start]) and not np.isnan(x_coords[end]) and not np.isnan(y_coords[end]):
                start_point = (int(x_coords[start] * FRAME_WIDTH), int(y_coords[start] * FRAME_LENGTH))
                end_point = (int(x_coords[end] * FRAME_WIDTH), int(y_coords[end] * FRAME_LENGTH))
                cv2.line(image, start_point, end_point, CONNECTION_COLOR, LINE_THICKNESS)
        
        for x, y in zip(x_coords, y_coords):
            if not np.isnan(x) and not np.isnan(y):
                cv2.circle(image, (int(x * FRAME_WIDTH), int(y * FRAME_LENGTH)), POINT_THICKNESS, POINT_COLOR, -1)

    # Draw pose landmarks and connections
    draw_landmarks_and_connections(frame_data["pose_x"], frame_data["pose_y"], links, image)

    # Draw hand landmarks and connections, if present
    if not all(np.isnan(frame_data["hand1_x"])):
        draw_landmarks_and_connections(frame_data["hand1_x"], frame_data["hand1_y"], connections, image)
    if not all(np.isnan(frame_data["hand2_x"])):
        draw_landmarks_and_connections(frame_data["hand2_x"], frame_data["hand2_y"], connections, image)

    return image


# def generate_image(frame_data):
#     FRAME_LENGTH = 4032
#     FRAME_WIDTH = 3024
#     POINT_COLOR = (255, 0, 0)
#     CONNECTION_COLOR = (0, 255, 0)
#     THICKNESS = 2

#     image = np.zeros((FRAME_LENGTH, FRAME_WIDTH, 3), np.uint8)
#     pose_x = frame_data["pose_x"]
#     pose_y = frame_data["pose_y"]
#     hand1_x = frame_data["hand1_x"]
#     hand1_y = frame_data["hand1_y"]
#     hand2_x = frame_data["hand2_x"]
#     hand2_y = frame_data["hand2_y"]

#     connections = [
#         (0, 1),
#         (1, 2),
#         (2, 3),
#         (3, 4),
#         (5, 6),
#         (6, 7),
#         (7, 8),
#         (9, 10),
#         (10, 11),
#         (11, 12),
#         (13, 14),
#         (14, 15),
#         (15, 16),
#         (17, 18),
#         (18, 19),
#         (19, 20),
#         (0, 5),
#         (5, 9),
#         (9, 13),
#         (13, 17),
#         (0, 17),
#     ]

#     links = [
#         (11, 12),
#         (11, 23),
#         (12, 24),
#         (23, 24),
#         (11, 13),
#         (13, 15),
#         (12, 14),
#         (14, 16),
#         (15, 21),
#         (15, 17),
#         (17, 19),
#         (19, 15),
#         (22, 16),
#         (16, 18),
#         (18, 20),
#         (16, 20),
#     ]

#     # Check if hand1_x and hand1_y are not empty and not nan before drawing
#     if len(hand1_x) > 0 and not np.isnan(hand1_x[0]):
#         image = draw_hands(image, hand1_x, hand1_y, connections, CONNECTION_COLOR, THICKNESS, POINT_COLOR, FRAME_LENGTH, FRAME_WIDTH)

#     # Check if hand2_x and hand2_y are not empty and not nan before drawing
#     if len(hand2_x) > 0 and not np.isnan(hand2_x[0]):
#         image = draw_hands(image, hand2_x, hand2_y, connections, CONNECTION_COLOR, THICKNESS, POINT_COLOR, FRAME_LENGTH, FRAME_WIDTH)

#     image = draw_pose(image, pose_x, pose_y, links, CONNECTION_COLOR, THICKNESS, POINT_COLOR, FRAME_LENGTH, FRAME_WIDTH)

#     return image

def replace_nan(x, y):
    x = 0.0 if np.isnan(x) else x
    y = 0.0 if np.isnan(y) else y
    return int(x * FRAME_WIDTH), int(y * FRAME_LENGTH)



def draw_hands(image, hand_x, hand_y, connections, connection_color, thickness, point_color, frame_length, frame_width):
    for connection in connections:
        x0, y0 = replace_nan(hand_x[connection[0]] * frame_width, hand_y[connection[0]] * frame_length)
        x1, y1 = replace_nan(hand_x[connection[1]] * frame_width, hand_y[connection[1]] * frame_length)

        cv2.line(image, (int(x0), int(y0)), (int(x1), int(y1)), connection_color, thickness)

    for x, y in zip(hand_x, hand_y):
        x, y = replace_nan(x * frame_width, y * frame_length)
        cv2.circle(image, (int(x), int(y)), thickness, point_color, thickness)

    return image


def draw_pose(image, pose_x, pose_y, links, connection_color, thickness, point_color, frame_length, frame_width):
    for link in links:
        x0, y0 = replace_nan(pose_x[link[0]] * frame_width, pose_y[link[0]] * frame_length)
        x1, y1 = replace_nan(pose_x[link[1]] * frame_width, pose_y[link[1]] * frame_length)

        cv2.line(image, (int(x0), int(y0)), (int(x1), int(y1)), connection_color, thickness)
        cv2.circle(image, (int(x0), int(y0)), thickness, point_color, thickness)
        cv2.circle(image, (int(x1), int(y1)), thickness, point_color, thickness)

    return image

connections = [
        (0, 1),
        (1, 2),
        (2, 3),
        (3, 4),
        (5, 6),
        (6, 7),
        (7, 8),
        (9, 10),
        (10, 11),
        (11, 12),
        (13, 14),
        (14, 15),
        (15, 16),
        (17, 18),
        (18, 19),
        (19, 20),
        (0, 5),
        (5, 9),
        (9, 13),
        (13, 17),
        (0, 17),
    ]

links = [
        (11, 12),
        (11, 23),
        (12, 24),
        (23, 24),
        (11, 13),
        (13, 15),
        (12, 14),
        (14, 16),
        (15, 21),
        (15, 17),
        (17, 19),
        (19, 15),
        (22, 16),
        (16, 18),
        (18, 20),
        (16, 20),
    ]

class_list = [...]
BUFFER_SIZE = 40
NEW_FRAMES_FOR_PREDICTION = 40

buffer = deque([np.zeros((224, 224, 3), dtype=np.float16) for _ in range(BUFFER_SIZE)], maxlen=BUFFER_SIZE)
model = keras.models.load_model('model_checkpoint.h5', compile=False)
display_width = 800
display_height = int(display_width * (3024 / 4032))

def update_buffer_and_predict(new_frame, buffer, frames_since_last_prediction):
    frame = tf.image.resize(new_frame, [224, 224]) 
    frame = tf.cast(frame, tf.float16) / 255.0  
    buffer.append(frame)
    frames_since_last_prediction += 1
    
    if frames_since_last_prediction >= NEW_FRAMES_FOR_PREDICTION:
        model_input = np.expand_dims(np.array(buffer), axis=0)
        prediction = model.predict(model_input)
        predicted_classes = np.argmax(prediction, axis=1)
        frames_since_last_prediction = 0  
        return predicted_classes, frames_since_last_prediction
    
    return None, frames_since_last_prediction

cap = cv2.VideoCapture(0)
frames_since_last_prediction = 0 

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        break

    frame_data = process_single_frame(frame)
    if frame_data:
        landmark_image = generate_image(frame_data)

        landmark_image_resized = cv2.resize(landmark_image, (display_width, display_height))
        cv2.imshow('Landmark Image', landmark_image_resized)

        model_output, frames_since_last_prediction = update_buffer_and_predict(landmark_image, buffer, frames_since_last_prediction)
        
        if model_output is not None:
            predicted_class_index = model_output[0]
            predicted_class_name = class_list[predicted_class_index]
            print(f"Predicted class: {predicted_class_name}")

    if cv2.waitKey(5) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()