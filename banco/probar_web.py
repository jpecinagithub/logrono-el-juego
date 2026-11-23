import sys, asyncio, base64
from playwright.async_api import async_playwright

URL = sys.argv[1]
PREF = sys.argv[2]
PROXY = len(sys.argv) > 3 and sys.argv[3] == "proxy"
LOG = "/tmp/%s_logs.txt" % PREF
EXE = "/home/hatch/.cache/ms-playwright/chromium-1254/chrome-linux64/chrome"

async def main():
    logs = open(LOG, "w")
    def on_console(m):
        try:
            logs.write(m.text + "\n"); logs.flush()
        except Exception:
            pass
    async with async_playwright() as pw:
        kw = {"executable_path": EXE, "args": ["--use-gl=swiftshader", "--enable-unsafe-swiftshader", "--no-sandbox"]}
        if PROXY:
            kw["proxy"] = {"server": "http://127.0.0.1:18080"}
        browser = await pw.chromium.launch(**kw)
        page = await browser.new_page(viewport={"width": 960, "height": 540})
        page.on("console", on_console)
        await page.goto(URL)
        ok = False
        for i in range(75):
            await page.wait_for_timeout(2000)
            try:
                txt = open(LOG).read()
            except Exception:
                txt = ""
            if "TACTIL_OK" in txt:
                ok = True
                break
        print("BOOT_OK" if ok else "BOOT_SIN_TACTIL", flush=True)
        if not ok:
            await browser.close()
            return
        cdp = await page.context.new_cdp_session(page)
        async def shot(path):
            try:
                r = await cdp.send("Page.captureScreenshot", {"format": "png"})
                open(path, "wb").write(base64.b64decode(r["data"]))
            except Exception as e:
                print("shot fallo", e, flush=True)
        # La ayuda se abre sola al arrancar: se cierra con Enter.
        await page.keyboard.press("Enter")
        await page.wait_for_timeout(600)
        await page.mouse.click(480, 300)
        for paso in range(8):
            for k in ["w", "a", "w", "d", "w"]:
                await page.keyboard.down(k)
                await page.wait_for_timeout(5400)
                await page.keyboard.up(k)
            if paso == 1:
                await page.keyboard.press("e")
            await shot("/tmp/%s_prog_%d.png" % (PREF, paso + 1))
        await shot("/tmp/%s_fuera.png" % PREF)
        await browser.close()
        print("FIN", flush=True)

asyncio.run(main())
