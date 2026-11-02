import subprocess
import os
import shutil
from pathlib import Path
from PIL import Image, ImageDraw

def render_svg_to_png(svg_path: Path, output_png: Path, size=1024):
    html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: {size}px; height: {size}px; overflow: hidden; background: transparent; }}
  svg {{ width: {size}px; height: {size}px; display: block; }}
</style>
</head>
<body>
{svg_path.read_text(encoding='utf-8')}
</body>
</html>"""
    
    temp_html = svg_path.parent / "temp_render.html"
    temp_html.write_text(html_content, encoding='utf-8')

    edge_bin = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if not os.path.exists(edge_bin):
        edge_bin = r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    
    cmd = [
        edge_bin,
        "--headless",
        "--disable-gpu",
        f"--window-size={size},{size}",
        f"--screenshot={output_png.resolve()}",
        "--default-background-color=00000000",
        str(temp_html.resolve())
    ]
    
    res = subprocess.run(cmd, capture_output=True, text=True)
    if temp_html.exists():
        temp_html.unlink()
        
    if not output_png.exists():
        raise RuntimeError(f"Screenshot failed: {res.stderr}")
    print(f"Rendered {output_png} ({size}x{size})")

def make_round_icon(img: Image.Image) -> Image.Image:
    # Create circular mask
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, img.size[0] - 1, img.size[1] - 1), fill=255)
    
    round_img = Image.new('RGBA', img.size, (0, 0, 0, 0))
    round_img.paste(img, (0, 0), mask=mask)
    return round_img

def main():
    root = Path(r"D:\Visikom")
    svg_file = root / "assets" / "padiscan_app_icon.svg"
    master_png = root / "assets" / "padiscan_app_icon_1024.png"
    
    render_svg_to_png(svg_file, master_png, size=1024)
    
    # Load master image
    img = Image.open(master_png).convert("RGBA")
    
    # Ensure 1024x1024 exact crop/size
    if img.size != (1024, 1024):
        img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # Android resolutions
    resolutions = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    
    res_dir = root / "app" / "android" / "app" / "src" / "main" / "res"
    
    for folder, dim in resolutions.items():
        target_dir = res_dir / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        
        # Standard icon
        resized = img.resize((dim, dim), Image.Resampling.LANCZOS)
        out_standard = target_dir / "ic_launcher.png"
        resized.save(out_standard, "PNG")
        print(f"Saved: {out_standard} ({dim}x{dim})")
        
        # Round icon
        round_icon = make_round_icon(resized)
        out_round = target_dir / "ic_launcher_round.png"
        round_icon.save(out_round, "PNG")
        print(f"Saved: {out_round} ({dim}x{dim})")
        
    # Also save 512x512 store icon
    store_icon = img.resize((512, 512), Image.Resampling.LANCZOS)
    store_icon.save(root / "assets" / "padiscan_playstore_512.png", "PNG")
    print("Saved: assets/padiscan_playstore_512.png")
    
    print("\nSUCCESS: All launcher icons generated from SVG!")

if __name__ == "__main__":
    main()
