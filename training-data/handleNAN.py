import os
import json
import numpy as np

def set_nan_to_zero(frames):
    # Convert each frame's keypoints from NaN to 0
    for i, frame in enumerate(frames):
        frames[i] = [0 if np.isnan(x) else x for x in frame]
    return frames

def process_and_clean_keypoints(directory):
    for filename in os.listdir(directory):
        if filename.endswith('.json'):
            file_path = os.path.join(directory, filename)
            with open(file_path, 'r') as f:
                data = json.load(f)

            # Apply NaN to 0 conversion for each keypoints list
            for key in ['pose_x', 'pose_y', 'hand1_x', 'hand1_y', 'hand2_x', 'hand2_y']:
                if key in data:
                    data[key] = set_nan_to_zero(data[key])

            # Save the updated data back to the JSON file
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=4)

if __name__ == "__main__":
    json_directory = '/Users/admin49/Downloads/INCLUDE-master/savedKeypoints/train'  # Update this path
    process_and_clean_keypoints(json_directory)
