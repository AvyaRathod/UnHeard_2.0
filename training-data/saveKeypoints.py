import os
import json
import cv2
import mediapipe as mp
from tqdm import tqdm
import numpy as np
from multiprocessing import Pool

mpHands = mp.solutions.hands
mpPose = mp.solutions.pose

# Function to determine if hands need to be swapped
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

# Function to process and store keypoints for a video
def process_video(video_path, save_path):
    with mpPose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose, \
         mpHands.Hands(max_num_hands=2, min_detection_confidence=0.75, min_tracking_confidence=0.5) as hands:

        cap = cv2.VideoCapture(video_path)
        frame_count = 0
        uid = os.path.splitext(os.path.basename(video_path))[0]
        label = os.path.basename(os.path.dirname(video_path))
        pose_points_x, pose_points_y = [], []
        hand1_points_x, hand1_points_y = [], []
        hand2_points_x, hand2_points_y = [], []

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            frame_results = pose.process(frame_rgb)
            hand_results = hands.process(frame_rgb)

            pose_landmarks = process_landmarks(frame_results.pose_landmarks)
            # Check if multi_hand_landmarks is not None before processing
            hand1_landmarks = process_landmarks(hand_results.multi_hand_landmarks[0]) if hand_results.multi_hand_landmarks and len(hand_results.multi_hand_landmarks) > 0 else None
            hand2_landmarks = process_landmarks(hand_results.multi_hand_landmarks[1]) if hand_results.multi_hand_landmarks and len(hand_results.multi_hand_landmarks) > 1 else None

            # Check if hands need to be swapped
            swap = swap_hands(pose_landmarks, hand1_landmarks, hand2_landmarks)
            if swap:
                hand1_landmarks, hand2_landmarks = hand2_landmarks, hand1_landmarks

            pose_points_x.append([landmark[0] for landmark in pose_landmarks])
            pose_points_y.append([landmark[1] for landmark in pose_landmarks])
            hand1_points_x.append([landmark[0] for landmark in hand1_landmarks] if hand1_landmarks else [np.nan] * 21)
            hand1_points_y.append([landmark[1] for landmark in hand1_landmarks] if hand1_landmarks else [np.nan] * 21)
            hand2_points_x.append([landmark[0] for landmark in hand2_landmarks] if hand2_landmarks else [np.nan] * 21)
            hand2_points_y.append([landmark[1] for landmark in hand2_landmarks] if hand2_landmarks else [np.nan] * 21)

            frame_count += 1

        cap.release()

        save_data = {
            "uid": uid,
            "label": label,
            "pose_x": pose_points_x,
            "pose_y": pose_points_y,
            "hand1_x": hand1_points_x,
            "hand1_y": hand1_points_y,
            "hand2_x": hand2_points_x,
            "hand2_y": hand2_points_y,
            "n_frames": frame_count,
        }

        # Write keypoints data to JSON file
        with open(os.path.join(save_path, f"{uid}.json"), 'w') as f:
            json.dump(save_data, f)

# Function to process landmarks from MediaPipe and return coordinates
def process_landmarks(landmarks):
    if landmarks:
        return [(landmark.x, landmark.y) for landmark in landmarks.landmark]
    else:
        return [(np.nan, np.nan)] * 21  # Return a list of NaN values if no landmarks are detected

# Function to process all videos in a split
def process_video_wrapper(args):
    return process_video(*args)


# Updated function to process all videos in a split using multiprocessing
def process_split(split_name, include_dir, save_dir, num_processes=4):
    split_save_dir = os.path.join(save_dir, split_name)
    os.makedirs(split_save_dir, exist_ok=True)

    split_file_path = os.path.join(f'train_test_paths/{split_name}.txt')
    with open(split_file_path, 'r') as file:
        video_paths = [line.strip() for line in file if line.strip()]

    # Prepare a list of arguments for process_video function
    video_args = [(os.path.join(include_dir, video_path), split_save_dir) for video_path in video_paths if
                  os.path.isfile(os.path.join(include_dir, video_path))]

    # Create a pool of workers to process videos in parallel
    with Pool(num_processes) as pool:
        list(tqdm(pool.imap(process_video_wrapper, video_args), total=len(video_args),
                  desc=f"Processing {split_name} videos"))


# Example usage
if __name__ == "__main__":
    include_dir = 'data_forModel'
    save_dir = 'savedKeypoints'
    num_processes = 8  # Adjust based on your machine's CPU cores

    # Process train, val, and test splits in parallel
    for split_name in ['train', 'val', 'test']:
        process_split(split_name, include_dir, save_dir, num_processes)

    print("Keypoint extraction and saving to JSON files completed for all splits.")