# crop_image.py
from PIL import Image
import json
import os
import argparse

# -----------------------------
# 지원 해상도 목록
# (width, height)
# -----------------------------
CANDIDATES = [
    (480, 832),  # 세로형
    (512, 512),  # 정방형
    (832, 480),  # 가로형
]

def choose_best_resolution(src_w, src_h):
    src_ratio = src_w / src_h

    best_w, best_h = None, None
    best_diff = float("inf")

    for w, h in CANDIDATES:
        diff = abs(src_ratio - (w / h))
        if diff < best_diff:
            best_diff = diff
            best_w, best_h = w, h

    return best_w, best_h

def preprocess_image(input_image_path, output_dir):
    # -----------------------------
    # 입력 이미지 로드
    # -----------------------------
    if not os.path.exists(input_image_path):
        raise FileNotFoundError(f"Input image not found: {input_image_path}")

    src = Image.open(input_image_path).convert("RGB")
    width, height = src.size
    src_ratio = width / height

    # -----------------------------
    # 타겟 해상도 선택
    # -----------------------------
    target_w, target_h = choose_best_resolution(width, height)
    target_ratio = target_w / target_h

    # -----------------------------
    # 중앙 크롭
    # -----------------------------
    if src_ratio > target_ratio:
        # 좌우 크롭
        new_width = int(height * target_ratio)
        left = (width - new_width) / 2
        right = (width + new_width) / 2
        top, bottom = 0, height
    else:
        # 상하 크롭
        new_height = int(width / target_ratio)
        top = (height - new_height) / 2
        bottom = (height + new_height) / 2
        left, right = 0, width

    cropped = src.crop((left, top, right, bottom))

    # -----------------------------
    # 리사이즈
    # -----------------------------
    resized = cropped.resize(
        (target_w, target_h),
        Image.Resampling.LANCZOS
    )

    # -----------------------------
    # 결과 저장
    # -----------------------------
    os.makedirs(output_dir, exist_ok=True)

    output_img_path = os.path.join(output_dir, "face.png")
    output_json_path = os.path.join(output_dir, "face_preproc.json")

    resized.save(output_img_path)

    info = {
        "width": target_w,
        "height": target_h
    }
    with open(output_json_path, "w") as f:
        json.dump(info, f, indent=2)

    print(f"[OK] Image saved to: {output_img_path}")
    print(f"[OK] Preprocess info saved to: {output_json_path}")

def main():
    parser = argparse.ArgumentParser(
        description="Crop and resize image to best supported aspect ratio"
    )
    parser.add_argument(
        "--input_image",
        type=str,
        required=True,
        help="Path to input image file (e.g. /data/input/face.jpg)"
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        required=True,
        help="Output directory path (face.png / face_preproc.json will be created)"
    )

    args = parser.parse_args()
    preprocess_image(args.input_image, args.output_dir)

if __name__ == "__main__":
    main()