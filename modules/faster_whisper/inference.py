import base64
from io import BytesIO

import torch
from faster_whisper import WhisperModel


class FasterWhisperInference:
    def __init__(
        self,
        model: str,
        device: str,
    ):
        if device == "cuda":
            if not torch.cuda.is_available():
                raise ValueError("CUDA is not available on this device.")
            else:
                self.device = "cuda"
        else:
            self.device = "cpu"

        self.compute_type = "float16" if self.device == "cuda" else "float32"

        self.model = WhisperModel(
            model,
            device=self.device,
            compute_type=self.compute_type,
        )

    def __del__(self):
        del self.model
        try:
            torch.cuda.empty_cache()
        except:
            pass

    def inference(
        self,
        audioRaw: str,
    ) -> any:
        fileBytes = base64.b64decode(audioRaw)

        segments, info = self.model.transcribe(BytesIO(fileBytes), beam_size=5)
        segments_list = list(segments)  # The transcription will actually run here.

        return " ".join([segment.text for segment in segments_list]).strip()


inference_name = FasterWhisperInference.__name__
