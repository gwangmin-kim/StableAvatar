# StableAvatar

StableAvatar: Infinite-Length Audio-Driven Avatar Video Generation
Original repository: https://github.com/Francis-Rings/StableAvatar

## What is changed
입력 이미지 전처리: 가까운 해상도에 맞춰 크롭

LoRA 적용 코드 추가

최종 출력물에서 비디오와 오디오를 병합

학습 코드 일부 수정

## Usage

For the basic version of the model checkpoint (Wan2.1-1.3B-based), it supports generating <b>infinite-length videos at a 480x832 or 832x480 or 512x512 resolution</b>. If you encounter insufficient memory issues, you can appropriately reduce the number of animated frames or the resolution of the output.

### My Environment
	•	Kubernetes Pod 기반
	•	NVIDIA CUDA 12.5 + Ubuntu 22.04
	•	1 GPU(A100 40GB)
	•	500GB PVC
	•	SSH 접속 가능 (Secret 기반)
	•	StableAvatar 실험을 위한 단일 Persistent 쉘 환경
참고: https://sgs-docs.snucse.org/usage/run-workload-examples.html
```
# stableavatar-shell.yaml
apiVersion: v1
kind: Pod
metadata:
  name: stableavatar-shell
spec:
  restartPolicy: Never
  nodeSelector:
    node-restriction.kubernetes.io/nodegroup: undergraduate
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: stableavatar-volume
    - name: ssh-auth
      secret:
        secretName: stableavatar-ssh
        defaultMode: 0400
  containers:
    - name: app
      image: nvcr.io/nvidia/cuda:12.5.0-base-ubuntu22.04
      ports:
        - containerPort: 22
      env:
        - name: HF_HOME
          value: /data/huggingface
        - name: PIP_CACHE_DIR
          value: /data/pip_cache
        - name: TMPDIR
          value: /data/tmp
        - name: TOKENIZERS_PARALLELISM
          value: "false"
      volumeMounts:
        - name: data
          mountPath: /data
        - name: ssh-auth
          mountPath: /root/.ssh/authorized_keys
          subPath: authorized_keys
          readOnly: true
      command: ["/bin/bash", "-c", "sleep inf"]
      resources:
        limits:
          nvidia.com/gpu: 1
```

### Environment setup

```
git clone https://github.com/gwangmin-kim/StableAvatar.git
cd StableAvatar
pip install --no-cache-dir \
  torch==2.6.0+cu124 \
  torchvision==0.21.0+cu124 \
  torchaudio==2.6.0+cu124 \
  --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir -r requirements.txt
pip install --no-cache-dir flash_attn
```

### Download weights
If you encounter connection issues with Hugging Face, you can utilize the mirror endpoint by setting the environment variable: `export HF_ENDPOINT=https://hf-mirror.com`.
Please download weights manually as follows:
```
pip install --no-cache-dir "huggingface_hub[cli]"
cd StableAvatar
mkdir -p checkpoints
huggingface-cli download FrancisRing/StableAvatar \
  --local-dir ./checkpoints \
  --local-dir-use-symlinks False \
  --resume-download
huggingface-cli download FrancisRing/StableAvatar --local-dir ./checkpoints
curl -L \
  https://github.com/gwangmin-kim/StableAvatar/releases/download/lora-s16000/lora-checkpoint-16000.pt \
  -o ./checkpoints/lora.pt
```

### Base Model inference
```
./inference.sh <image_path> <audio_path> <output_dir> [--steps N]
# [--steps N] is an optional parameter. default=50
# output video will be saved at <output_dir>/video.mp4
```

## Citation
```bib
@article{tu2025stableavatar,
  title={Stableavatar: Infinite-length audio-driven avatar video generation},
  author={Tu, Shuyuan and Pan, Yueming and Huang, Yinming and Han, Xintong and Xing, Zhen and Dai, Qi and Luo, Chong and Wu, Zuxuan and Jiang, Yu-Gang},
  journal={arXiv preprint arXiv:2508.08248},
  year={2025}
}
```
