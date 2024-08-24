import os
import numpy as np
import cv2
from matplotlib import pyplot as plt
import json

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

def load_json(file_path):
    with open(file_path, 'r') as file:
        data = json.load(file)
    return data


def replace_nan(x, y):
    x = 0.0 if np.isnan(x) else x
    y = 0.0 if np.isnan(y) else y
    return x, y


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


def process_and_save_images(json_directory, output_directory):
    for filename in os.listdir(json_directory):
        if filename.endswith('.json'):
            file_path = os.path.join(json_directory, filename)
            try:
                video_record = load_json(file_path)

                label = video_record['label']
                uuid = video_record['uid']

                # Define the directory path based on label and uuid
                label_dir = os.path.join(output_directory, label)
                uuid_dir = os.path.join(label_dir, uuid)

                # Create directories if they don't exist
                os.makedirs(uuid_dir, exist_ok=True)

                # Generate and save images for each frame in the video record
                for i in range(video_record["n_frames"]):
                    image = generate_image(video_record, i)

                    # Save the image
                    image_filename = f'{i}.png'
                    image_path = os.path.join(uuid_dir, image_filename)
                    cv2.imwrite(image_path, image)

            except Exception as e:
                print(f"Error processing file: {filename}. Error: {e}")
                continue

def generate_image(video_record, frame_index):
    FRAME_LENGTH = 4032
    FRAME_WIDTH = 3024
    POINT_COLOR = (255, 0, 0)
    CONNECTION_COLOR = (0, 255, 0)
    THICKNESS = 2

    # Assuming connections and links are defined globally or within this function

    image = np.zeros((FRAME_LENGTH, FRAME_WIDTH, 3), np.uint8)
    pose_x = video_record["pose_x"][frame_index]
    pose_y = video_record["pose_y"][frame_index]
    hand1_x = video_record["hand1_x"][frame_index]
    hand1_y = video_record["hand1_y"][frame_index]
    hand2_x = video_record["hand2_x"][frame_index]
    hand2_y = video_record["hand2_y"][frame_index]

    if hand1_x[0] != 0:
        image = draw_hands(image, hand1_x, hand1_y, connections, CONNECTION_COLOR, THICKNESS, POINT_COLOR, FRAME_LENGTH,
                           FRAME_WIDTH)

    if hand2_x[0] != 0:
        image = draw_hands(image, hand2_x, hand2_y, connections, CONNECTION_COLOR, THICKNESS, POINT_COLOR, FRAME_LENGTH,
                           FRAME_WIDTH)

    image = draw_pose(image, pose_x, pose_y, links, CONNECTION_COLOR, THICKNESS, POINT_COLOR, FRAME_LENGTH, FRAME_WIDTH)

    return image


# Path to your JSON files directory and the output directory where you want to store the images
for dir in ['val', 'test','train']:
    json_directory = f"savedKeypoints/{dir}"
    output_directory = f"savedKeypoints/{dir}_keypoint_frames_3024x4032"
    process_and_save_images(json_directory, output_directory)


