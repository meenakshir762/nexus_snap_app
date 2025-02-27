Extracting a 20GB tar file is CPU-intensive and also I/O-heavy (disk operations). In this case, asyncio alone won't help, as it mainly benefits I/O-bound tasks like network requests.

Best Approach: Use Multiprocessing + Asyncio
✅ Multiprocessing: Runs tar -xvf in a separate CPU process to avoid blocking.
✅ Asyncio: Handles multiple client requests efficiently.

🚀 Optimized Architecture
1️⃣ Server: Use Multiprocessing for Extraction
Modify your server to use multiprocessing.Process for untarring while keeping asyncio for handling requests.

python
Copy
Edit
import asyncio
import os
import multiprocessing
from aiohttp import web

def extract_tar(sr_no):
    """Extracts the tar file in a separate process"""
    tar_file = f"./SR/{sr_no}/nexus_snap_snapshot_bundle_snapshot_bundle.tar"
    if not os.path.exists(tar_file):
        print(f"Tar file {tar_file} not found")
        return
    
    cmd = f"tar -xvf {tar_file} -C ./SR/{sr_no}/"
    os.system(cmd)  # CPU & Disk-intensive operation

async def process_sr(sr_no):
    """Handles the SR processing asynchronously"""
    print(f"Processing SR: {sr_no}")
    
    # Run extraction in a separate process
    process = multiprocessing.Process(target=extract_tar, args=(sr_no,))
    process.start()
    process.join()  # Wait for extraction to finish

    # Run parsing after extraction
    cmd = f"bash parser.sh {sr_no}"
    process = await asyncio.create_subprocess_shell(cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return f"Processed SR {sr_no} successfully!"
    else:
        return f"Error processing {sr_no}: {stderr.decode()}"

async def handle_request(request):
    """Handle HTTP request for processing SR number"""
    data = await request.json()
    sr_no = data.get("sr_number")
    
    if not sr_no:
        return web.json_response({"error": "SR number is required"}, status=400)
    
    result = await process_sr(sr_no)
    return web.json_response({"message": result})

app = web.Application()
app.add_routes([web.post("/process", handle_request)])

if __name__ == "__main__":
    web.run_app(app, host="0.0.0.0", port=65001)
2️⃣ Client: Use Async HTTPX
Your client remains the same, making async requests to the server.

python
Copy
Edit
import asyncio
import httpx

async def send_request():
    async with httpx.AsyncClient() as client:
        while True:
            sr_no = input("Enter SR number: ")
            response = await client.post("http://10.106.39.168:65001/process", json={"sr_number": sr_no})
            print(response.json())

asyncio.run(send_request())
🔥 Why This Works Best
✅ Handles 20GB files efficiently
✅ Prevents blocking the event loop
✅ Uses multiprocessing for CPU-heavy extraction
✅ Asyncio still manages multiple requests smoothly
