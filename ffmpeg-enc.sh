#!/bin/bash

Q=$1
FILE=$2
CODEC=libx265
SCALE=1080

while read -r LINE; do
    if [[ "$LINE" =~ ^[[:space:]]*Stream.*:\ Video:\ ([^ ]+).*,\ ([0-9]+)x([0-9]+).*,\ ([0-9]+)\ kb\/s ]]; then
        # Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt709/bt709/smpte170m), 1080x1920 [SAR 1:1 DAR 9:16], 3265 kb/s, 30 fps, 30 tbr, 15360 tbn, 60 tbc (default)
        # Stream #0:0(und): Video: hevc (Main) (hev1 / 0x31766568), yuv420p(tv, progressive), 1080x1920 [SAR 1:1 DAR 9:16], 1491 kb/s, 30 fps, 30 tbr, 15360 tbn, 30 tbc (default)
        echo "Codec    = ${BASH_REMATCH[1]}"
        echo "Height   = ${BASH_REMATCH[2]}"
        echo "Width    = ${BASH_REMATCH[3]}"
        echo "Bitrate  = ${BASH_REMATCH[4]}"
        IN_CODEC=${BASH_REMATCH[1]}
        IN_HEIGHT=${BASH_REMATCH[2]}
        IN_WIDTH=${BASH_REMATCH[3]}
        IN_BITRATE=${BASH_REMATCH[4]}
    elif [[ "$LINE" =~ ^[[:space:]]*Stream.*:\ Audio:\ ([^ ]+) ]]; then
        # Stream #0:1(eng): Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 127 kb/s (default)
        echo "ACodec   = ${BASH_REMATCH[1]}"
        IN_ACODEC=${BASH_REMATCH[1]}
    fi
done < <(ffprobe $FILE 2>&1)

if [[ "${IN_CODEC}" == "" ]]; then
  echo "Unknown file"
  exit 1
elif [[ "${IN_CODEC}" == "hevc" ]]; then
  echo "Skip HECV"
  exit 0
fi

FILE_BASE=${FILE%.*}
FILE_EXT=${FILE##*.}
if [[ "${IN_ACODEC}" == "aac" ]]; then
  ARG_ACODEC="copy"
else
  ARG_ACODEC="aac"
fi

if [[ "${SCALE}" != "" ]]; then
  ARG_SCALE="-vf scale='-1:if(gt(ih,${SCALE}),${SCALE},-1)':flags=lanczos";
fi

if [[ ${Q} -gt 51 ]]; then
    # Two-pass bitrate
    ## ffmpeg -y -i MOV_0465.mp4 -preset fast -c:v libx265 -b:v 1500k -x265-params pass=1 -an -f mp4 /dev/null
    ## ffmpeg -i MOV_0465.mp4 -c:v libx265 -b:v 1500k -x265-params pass=2 -c:a aac -b:a 128k output.mp4
    ffmpeg -y -i "${FILE}" -preset fast -c:v ${CODEC} -b:v ${Q}k -x265-params pass=1 -an -f mp4 /dev/null
    ffmpeg -y -i "${FILE}" -c:v ${CODEC} ${ARG_SCALE} -b:v ${Q}k -x265-params pass=2 -c:a ${ARG_ACODEC} ${FILE_BASE}-${CODEC}-${Q}.${FILE_EXT} 2>&1
else
    # CRF
    # ffmpeg -i "${FILE}" -c:v libx265 -c:a aac -b:a 128k output-crf24.mp4
    ffmpeg -y -i "${FILE}" -c:v ${CODEC} ${ARG_SCALE} -crf ${Q} -c:a ${ARG_ACODEC} ${FILE_BASE}-${CODEC}-${Q}.${FILE_EXT} 2>&1
fi

## 



