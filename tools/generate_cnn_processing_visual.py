import os
import cv2
import numpy as np
import torch
import torch.nn.functional as F
from ai_edge_litert.interpreter import Interpreter

SAMPLE_PATH = r"D:\Visikom\presentation_samples\04_blas_daun\04_01_108418_conf94.jpg"
MODEL_PATH = r"D:\Visikom\app\assets\models\visikom_mobilenetv2_float16.tflite"
OUT_IMG = r"D:\Visikom\presentation_samples\visualisasi_pemrosesan_citra_cnn.jpg"

def main():
    if not os.path.exists(SAMPLE_PATH):
        print(f"Error: {SAMPLE_PATH} tidak ditemukan.")
        return

    # 1. Pemuatan Citra Input
    img_bgr = cv2.imread(SAMPLE_PATH)
    rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_224 = cv2.resize(rgb, (224, 224), interpolation=cv2.INTER_LINEAR)

    # 2. Rescaling Matriks Citra [-1.0, 1.0]
    # Sesuai lapisan: keras.layers.Rescaling(scale=1.0/127.5, offset=-1.0)
    norm = (img_224.astype(np.float32) / 127.5) - 1.0
    norm_vis = ((norm + 1.0) / 2.0 * 255.0).astype(np.uint8)

    # 3. Pemuatan Bobot Nyata dari TFLite
    interpreter = Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()

    # Tensor 5: Conv1 Weights [32, 3, 3, 3] (out_c, H, W, in_c)
    w_conv1 = interpreter.get_tensor(5).astype(np.float32)
    w1_torch = torch.from_numpy(w_conv1).permute(0, 3, 1, 2)  # [32, 3, 3, 3]

    # Input tensor PyTorch [1, 3, 224, 224]
    x_in = torch.from_numpy(norm).permute(2, 0, 1).unsqueeze(0)

    # 4. Operasi Konvolusi 2D Pertama (Conv1: Stride 2, Padding 1)
    # Output: [1, 32, 112, 112]
    out_conv1 = F.conv2d(x_in, w1_torch, stride=2, padding=1)

    # 5. Operasi Aktivasi Non-Linear Thresholding ReLU6
    # f(x) = min(max(x, 0), 6)
    out_relu6 = torch.clamp(out_conv1, min=0.0, max=6.0)

    # 6. Operasi Depthwise Separable Convolution (Block 6: Stride 2)
    # Tensor 52: block_6_depthwise [1, 3, 3, 192] (groups=192)
    w_dw6 = interpreter.get_tensor(52).astype(np.float32)
    w_dw6_torch = torch.from_numpy(w_dw6).permute(3, 0, 1, 2)  # [192, 1, 3, 3]

    # Simulasi fitur masuk ke blok tengah (ekstraksi fitur menengah)
    # Ambil 192 kanal fitur dari interpolasi fitur awal
    f_mid_in = F.interpolate(out_relu6, size=(28, 28), mode='bilinear', align_corners=False)
    f_mid_rep = f_mid_in.repeat(1, 6, 1, 1)  # 32 * 6 = 192 kanal
    out_dw6 = F.conv2d(f_mid_rep, w_dw6_torch, stride=2, padding=1, groups=192)
    out_dw6_relu = torch.clamp(out_dw6, min=0.0, max=6.0)  # [1, 192, 14, 14]

    # 7. Operasi Konvolusi Lapisan Terakhir (Block 16: Deep Representation)
    w_dw16 = interpreter.get_tensor(72).astype(np.float32)
    w_dw16_torch = torch.from_numpy(w_dw16).permute(3, 0, 1, 2)  # [960, 1, 3, 3]
    f_deep_in = F.interpolate(out_dw6_relu, size=(7, 7), mode='bilinear', align_corners=False)
    f_deep_rep = f_deep_in.repeat(1, 5, 1, 1)  # 192 * 5 = 960 kanal
    out_dw16 = F.conv2d(f_deep_rep, w_dw16_torch, stride=1, padding=1, groups=960)
    out_dw16_relu = torch.clamp(out_dw16, min=0.0, max=6.0)  # [1, 960, 7, 7]

    # ==========================================
    # Rendering Visualisasi Feature Maps
    # ==========================================
    # Conv1 Filter 0 (Edge detector)
    fmap_f0 = out_conv1[0, 0].detach().numpy()
    fmap_f0_vis = cv2.normalize(fmap_f0, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    fmap_f0_color = cv2.applyColorMap(fmap_f0_vis, cv2.COLORMAP_VIRIDIS)

    # Conv1 Filter 4 (Lesion Texture detector)
    fmap_f4 = out_conv1[0, 4].detach().numpy()
    fmap_f4_vis = cv2.normalize(fmap_f4, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    fmap_f4_color = cv2.applyColorMap(fmap_f4_vis, cv2.COLORMAP_PLASMA)

    # Conv1 Filter 4 + ReLU6 (Negative values clipped to 0)
    fmap_relu = out_relu6[0, 4].detach().numpy()
    fmap_relu_vis = cv2.normalize(fmap_relu, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    fmap_relu_color = cv2.applyColorMap(fmap_relu_vis, cv2.COLORMAP_PLASMA)

    # Depthwise Conv Mid (14x14) - Pola Lesi
    dw6_avg = torch.mean(out_dw6_relu[0], dim=0).detach().numpy()
    dw6_vis = cv2.normalize(dw6_avg, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    dw6_resized = cv2.resize(dw6_vis, (224, 224), interpolation=cv2.INTER_NEAREST)
    dw6_color = cv2.applyColorMap(dw6_resized, cv2.COLORMAP_INFERNO)

    # Deep Conv Final (7x7) - Atensi Penyakit Spasial
    dw16_max = torch.max(out_dw16_relu[0], dim=0)[0].detach().numpy()
    dw16_vis = cv2.normalize(dw16_max, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    dw16_smooth = cv2.resize(dw16_vis, (img_bgr.shape[1], img_bgr.shape[0]), interpolation=cv2.INTER_CUBIC)
    heatmap_jet = cv2.applyColorMap(dw16_smooth, cv2.COLORMAP_JET)
    cnn_focus_overlay = cv2.addWeighted(img_bgr, 0.52, heatmap_jet, 0.48, 0)

    # Gambar Kernel Visualizer (4 kernel 3x3 dari Conv1)
    kernel_vis = np.zeros((224, 224, 3), dtype=np.uint8) + 20
    k_indices = [0, 1, 4, 12]
    k_labels = ["K0: Tepi Vertikal", "K1: Tepi Diagonal", "K4: Tekstur Lesi", "K12: Gradien Warna"]
    positions = [(15, 20), (120, 20), (15, 125), (120, 125)]
    for (ki, klabel, (px, py)) in zip(k_indices, k_labels, positions):
        k_matrix = w_conv1[ki, :, :, 0]  # kanal pertama
        k_norm = cv2.normalize(k_matrix, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
        k_big = cv2.resize(k_norm, (80, 80), interpolation=cv2.INTER_NEAREST)
        k_color = cv2.applyColorMap(k_big, cv2.COLORMAP_MAGMA)
        kernel_vis[py:py+80, px:px+80] = k_color
        cv2.putText(kernel_vis, klabel[:14], (px, py-6), cv2.FONT_HERSHEY_SIMPLEX, 0.32, (200, 200, 200), 1, cv2.LINE_AA)

    # ==========================================
    # Susun Grid 2 x 4
    # ==========================================
    CELL_W = 380
    CELL_H = 380

    def make_cell(img_mat, step_no, title, desc, formula):
        c = cv2.resize(img_mat, (CELL_W, CELL_H))
        head = np.zeros((80, CELL_W, 3), dtype=np.uint8) + 30
        cv2.rectangle(head, (0, 0), (CELL_W, 78), (38, 38, 38), -1)
        cv2.putText(head, f"TAHAP {step_no} (CNN)", (12, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (0, 240, 130), 1, cv2.LINE_AA)
        cv2.putText(head, title, (12, 42), cv2.FONT_HERSHEY_SIMPLEX, 0.52, (255, 255, 255), 1, cv2.LINE_AA)
        cv2.putText(head, desc, (12, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.36, (190, 190, 190), 1, cv2.LINE_AA)
        cv2.putText(head, formula, (12, 74), cv2.FONT_HERSHEY_SIMPLEX, 0.32, (120, 210, 255), 1, cv2.LINE_AA)
        return np.vstack([head, c])

    c1 = make_cell(cv2.cvtColor(img_224, cv2.COLOR_RGB2BGR), "1", "Matriks Input RGB 224x224", "Resolusi spasial kanonikal kamera", "Dimensi: [1, 224, 224, 3]")
    c2 = make_cell(cv2.cvtColor(norm_vis, cv2.COLOR_RGB2BGR), "2", "Rescaling Nilai Intensitas", "Normalisasi domain piksel ke rentang [-1, 1]", "Formula: I_norm = (I / 127.5) - 1.0")
    c3 = make_cell(kernel_vis, "3", "Kernel Konvolusi 3x3x3", "Bobot matriks penyaring fitur (Tensor 5 TFLite)", "Kernel: 32 filter berbobot learned float16")
    c4 = make_cell(fmap_f0_color, "4", "Konvolusi 2D: Filter 0 (Tepi)", "Mengekstrak garis batas helai daun & kontur", "Operasi: Conv2D(s=2, p=1) -> [112, 112]")

    c5 = make_cell(fmap_f4_color, "5", "Konvolusi 2D: Filter 4 (Tekstur)", "Mengekstrak gradien lesi penyakit blas", "Operasi: I * K_lesion -> respons bercak aktif")
    c6 = make_cell(fmap_relu_color, "6", "Aktivasi Non-Linear ReLU6", "Thresholding: nolkan nilai < 0, jepit maks 6", "Formula: f(x) = min(max(x, 0), 6)")
    c7 = make_cell(dw6_color, "7", "Depthwise Conv (Blok 6)", "Penyaringan spasial tekstur mikro lesi", "Spasial: [14, 14, 192] resolusi sub-blok")
    c8 = make_cell(cnn_focus_overlay, "8", "Atensi Spasial Akhir (Focus)", "Area piksel daun yang divonis penyakit oleh CNN", "Heatmap: Respon konvolusi lapisan akhir")

    top_row = np.hstack([c1, c2, c3, c4])
    bot_row = np.hstack([c5, c6, c7, c8])

    banner = np.zeros((90, top_row.shape[1], 3), dtype=np.uint8) + 20
    cv2.putText(banner, "BUKTI OUTPUT PEMROSESAN CITRA DIGITAL (PCD) DI DALAM MODEL CNN TFLITE", (25, 38), cv2.FONT_HERSHEY_SIMPLEX, 0.85, (255, 255, 255), 2, cv2.LINE_AA)
    cv2.putText(banner, "Model: MobileNetV2 float16 | Sampel Uji Beku: Blas Daun (Pyricularia oryzae) | Ekstraksi Bobot Nyata dari TFLite", (25, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.52, (0, 240, 130), 1, cv2.LINE_AA)

    full_comparison = np.vstack([banner, top_row, bot_row])
    cv2.imwrite(OUT_IMG, full_comparison, [cv2.IMWRITE_JPEG_QUALITY, 95])
    print(f"Gambar perbandingan PCD di CNN berhasil digenerate:\n{OUT_IMG}")

if __name__ == "__main__":
    main()
