import cv2
import numpy as np
import os
from ai_edge_litert.interpreter import Interpreter

MODEL_PATH = r'D:\Visikom\app\assets\models\visikom_mobilenetv2_float16.tflite'
interpreter = Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

RAW_CLASSES = [
    'Bacterial Leaf Blight',
    'Brown Spot',
    'Healthy',
    'Leaf Blast',
    'Leaf Scald',
    'Sheath Blight'
]

INDONESIAN_CLASSES = [
    'Hawar Daun Bakteri (Kresek)',
    'Bercak Cokelat Daun',
    'Padi Sehat (Bebas Penyakit)',
    'Blas Daun (Penyakit Blas)',
    'Hawar Daun Bergaris (Scald)',
    'Busuk Pelepah Daun'
]

def calibrate_probs(probs, temperature=0.65):
    scaled = np.power(np.maximum(probs, 1e-6), 1.0 / temperature)
    return scaled / np.sum(scaled)

def cv_pipeline(img_bgr):
    h, w = img_bgr.shape[:2]
    max_dim = max(h, w)
    if max_dim > 640:
        scale = 640.0 / max_dim
        img_work = cv2.resize(img_bgr, (int(w * scale), int(h * scale)))
    else:
        img_work = img_bgr.copy()
    
    gray = cv2.cvtColor(img_work, cv2.COLOR_BGR2GRAY)
    blur_score = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    brightness = float(np.mean(gray))
    
    b, g, r = cv2.split(img_work.astype(np.float32))
    total = r + g + b + 1e-5
    exg = (2.0 * g - r - b) / total
    
    min_exg, max_exg = float(np.min(exg)), float(np.max(exg))
    exg_range = (max_exg - min_exg) if (max_exg - min_exg) > 0 else 1.0
    exg_8u = np.clip((exg - min_exg) / exg_range * 255.0, 0, 255).astype(np.uint8)
    
    _, otsu_mask = cv2.threshold(exg_8u, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (7, 7))
    leaf_mask = cv2.morphologyEx(otsu_mask, cv2.MORPH_CLOSE, kernel)
    
    total_pixels = leaf_mask.size
    leaf_pixels = int(np.count_nonzero(leaf_mask))
    leaf_ratio = leaf_pixels / total_pixels
    
    # Is leaf validation
    mean_exg = float(np.mean(exg))
    green_veg_ratio = np.count_nonzero(exg > 0.05) / total_pixels
    is_leaf = bool(green_veg_ratio >= 0.05 and mean_exg > -0.05 and leaf_ratio >= 0.04)
    
    lab = cv2.cvtColor(img_work, cv2.COLOR_BGR2LAB)
    l, a, b_ch = cv2.split(lab)
    # Lesion: necrosis (a > 132) OR chlorosis hawar (leaf pixel with exg < 0.05)
    lesion_mask = (leaf_mask > 0) & ((a > 132) | (exg < 0.05))
    lesion_pixels = int(np.count_nonzero(lesion_mask))
    lesion_ratio = (lesion_pixels / leaf_pixels) if leaf_pixels > 0 else 0.0
    
    severity = 0
    if lesion_ratio > 0.30: severity = 4
    elif lesion_ratio > 0.15: severity = 3
    elif lesion_ratio > 0.05: severity = 2
    elif lesion_ratio > 0.001: severity = 1
    
    return {
        'is_leaf': is_leaf,
        'blur_score': blur_score,
        'brightness': brightness,
        'leaf_ratio': leaf_ratio,
        'lesion_ratio': lesion_ratio,
        'severity': severity
    }

test_dir = r'D:\Visikom\test_external_images'
print('=== PENGUJIAN CITRA EKSTERNAL DI LUAR DATASET ===\n')

for fname in sorted(os.listdir(test_dir)):
    fpath = os.path.join(test_dir, fname)
    img_bgr = cv2.imread(fpath)
    if img_bgr is None: continue
    
    cv_res = cv_pipeline(img_bgr)
    
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_224 = cv2.resize(img_rgb, (224, 224), interpolation=cv2.INTER_LINEAR)
    inp = np.expand_dims(img_224.astype(np.float32), axis=0)
    
    interpreter.set_tensor(input_details[0]['index'], inp)
    interpreter.invoke()
    raw_probs = interpreter.get_tensor(output_details[0]['index'])[0]
    
    cal_probs = calibrate_probs(raw_probs)
    
    raw_idx = int(np.argmax(raw_probs))
    raw_class = RAW_CLASSES[raw_idx]
    raw_conf = float(raw_probs[raw_idx])
    
    cal_idx = int(np.argmax(cal_probs))
    cal_class = INDONESIAN_CLASSES[cal_idx]
    cal_conf = float(cal_probs[cal_idx])
    
    fused_idx = cal_idx
    fused_conf = cal_conf
    fusion_applied = False
    if cal_idx == 2 and (cv_res['lesion_ratio'] >= 0.010 or cv_res['severity'] >= 1):
        disease_probs = [cal_probs[i] if i != 2 else -1.0 for i in range(len(cal_probs))]
        fused_idx = int(np.argmax(disease_probs))
        fused_conf = float(cal_probs[fused_idx])
        fusion_applied = True
    
    fused_class = INDONESIAN_CLASSES[fused_idx]
    
    print(f'Berkas: {fname}')
    print(f'  [CV Gate] Deteksi Daun: {cv_res["is_leaf"]} | Luas Daun: {cv_res["leaf_ratio"]*100:.1f}% | Rasio Lesi: {cv_res["lesion_ratio"]*100:.2f}% | Skor Keparahan: {cv_res["severity"]}')
    print(f'  [CNN Raw Mentah]     : {raw_class} (Keyakinan: {raw_conf*100:.1f}%)')
    print(f'  [CNN Terkalibrasi]  : {cal_class} (Keyakinan: {cal_conf*100:.1f}%)')
    if fusion_applied:
        print(f'  [DECISION FUSION]   : CNN menebak Sehat tapi CV mendeteksi lesi {cv_res["lesion_ratio"]*100:.2f}%. Dikoreksi ke -> {fused_class} ({fused_conf*100:.1f}%)')
    
    status_str = "DITOLAK (Bukan Daun Padi)" if not cv_res["is_leaf"] else f"{fused_class} [{fused_conf*100:.1f}%]"
    print(f'  >>> OUTPUT SISTEM   : {status_str}')
    print('-' * 70)
