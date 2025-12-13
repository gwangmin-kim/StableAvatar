export TOKENIZERS_PARALLELISM=false
export NCCL_IB_DISABLE=1
export NCCL_P2P_DISABLE=1
NCCL_DEBUG=INFO

DIR="/data/workspace/StableAvatar"
MODEL_NAME="$DIR/checkpoints/Wan2.1-Fun-V1.1-1.3B-InP"

DATA_DIR="/data/dataset/talking_face_data"

CUDA_VISIBLE_DEVICES=0,1,2,3 accelerate launch "$DIR/train_1B_square.py" \
  --config_path="$DIR/deepspeed_config/wan2.1/wan_civitai.yaml" \
  --pretrained_model_name_or_path=$MODEL_NAME \
  --pretrained_wav2vec_path="$DIR/checkpoints/wav2vec2-base-960h" \
  --validation_reference_path="$DIR/validation/reference.png" \
  --validation_driven_audio_path="$DIR/validation/audio.wav" \
  --train_data_square_dir="$DATA_DIR/video_square_path.txt"  \
  --video_sample_n_frames=81 \
  --train_batch_size=1 \
  --video_repeat=1 \
  --gradient_accumulation_steps=1 \
  --dataloader_num_workers=0 \
  --num_train_epochs=1000 \
  --checkpointing_steps=2000 \
  --validation_steps=500 \
  --learning_rate=2e-05 \
  --lr_scheduler="constant_with_warmup" \
  --lr_warmup_steps=100 \
  --seed=42 \
  --output_dir="$DIR/output_1B_square_dir" \
  --gradient_checkpointing \
  --mixed_precision="bf16" \
  --adam_weight_decay=3e-2 \
  --adam_epsilon=1e-10 \
  --vae_mini_batch=1 \
  --max_grad_norm=0.05 \
  --uniform_sampling \
  --motion_sub_loss \
  --low_vram \
  --train_mode="i2v"