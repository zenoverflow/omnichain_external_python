import torch
from PIL import Image
from transformers import AutoProcessor, AutoModelForCausalLM
from io import BytesIO
import base64


class Florence2Inference:
    def __init__(self, device: str = "cpu", model: str = "microsoft/Florence-2-large"):
        if device == "cuda":
            if not torch.cuda.is_available():
                raise ValueError("CUDA is not available on this device.")
            else:
                self.device = "cuda"
        else:
            self.device = "cpu"

        self.torch_dtype = torch.float16 if self.device == "cuda" else torch.float32

        self.model = AutoModelForCausalLM.from_pretrained(
            model,
            torch_dtype=self.torch_dtype,
            trust_remote_code=True,
        ).to(self.device)

        self.processor = AutoProcessor.from_pretrained(model, trust_remote_code=True)

    def __del__(self):
        del self.model
        del self.processor
        try:
            torch.cuda.empty_cache()
        except:
            pass

    def inference(
        self,
        task_prompt: str,
        imageRaw: str,
        text_input: str | None = None,
    ) -> any:
        if text_input is None:
            prompt = task_prompt
        else:
            prompt = task_prompt + text_input

        # decode image from base64
        image = Image.open(BytesIO(base64.b64decode(imageRaw))).convert("RGB")

        inputs = self.processor(text=prompt, images=image, return_tensors="pt").to(
            self.device, self.torch_dtype
        )

        generated_ids = self.model.generate(
            input_ids=inputs["input_ids"],
            pixel_values=inputs["pixel_values"],
            max_new_tokens=1024,
            early_stopping=False,
            do_sample=False,
            num_beams=3,
        )
        generated_text = self.processor.batch_decode(
            generated_ids, skip_special_tokens=False
        )[0]

        parsed_answer = self.processor.post_process_generation(
            generated_text,
            task=task_prompt,
            image_size=(image.width, image.height),
        )

        return parsed_answer


inference_name = Florence2Inference.__name__
