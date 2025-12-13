#!/usr/bin/env bash
set -e

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <image_path> <audio_path> <output_dir>"
  exit 1
fi

IMAGE="$1"
AUDIO="$2"
OUTPUT_DIR="$3"

ROOT="/data"
REPO="$ROOT/workspace/StableAvatar"
INTERMEDIATE="$ROOT/workspace/intermediate"
mkdir -p $INTERMEDIATE

# crop image
python "$REPO/crop_image.py" \
    --input_image="$IMAGE" \
    --output_dir="$INTERMEDIATE"

# inference video
export TOKENIZERS_PARALLELISM=false
REF_IMAGE="$INTERMEDIATE/face.png"
DRIVEN_AUDIO="$INTERMEDIATE/audio.wav"

CUDA_VISIBLE_DEVICES=0 python "$REPO/inference.py" \
    --config_path="$REPO/deepspeed_config/wan2.1/wan_civitai.yaml" \
    --pretrained_model_name_or_path="$REPO/checkpoints/Wan2.1-Fun-V1.1-1.3B-InP" \
    --pretrained_wav2vec_path="$REPO/checkpoints/wav2vec2-base-960h" \
    --transformer_path="$REPO/checkpoints/StableAvatar-1.3B/transformer3d-square.pt" \
    --lora_path="$REPO/checkpoints/lora.pt" \
    --validation_reference_path="$REF_IMAGE" \
    --validation_driven_audio_path="$DRIVEN_AUDIO" \
    --validation_prompts="A young man looking straight at the camera with a calm and neutral expression." \
    --output_dir="$INTERMEDIATE" \
    --seed=42 \
    --ulysses_degree=1 \
    --ring_degree=1 \
    --motion_frame=30 \
    --sample_steps=50 \
    --width=832 \
    --height=480 \
    --overlap_window_length=10 \
    --clip_sample_n_frames=81 \
    --GPU_memory_mode="model_full_load" \
    --sample_text_guide_scale=5.0 \
    --sample_audio_guide_scale=5.0 \
    --input_perturbation=0.05

# combine with audio
ffmpeg -y -i "$INTERMEDIATE/video_without_audio.mp4" -i "$DRIVEN_AUDIO" \
  -c:v copy -c:a aac -shortest "$OUTPUT_DIR/video.mp4"
# rm "$INTERMEDIATE/video_without_audio.mp4"