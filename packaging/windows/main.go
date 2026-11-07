package main

import (
	"embed"
	"fmt"
	"io/fs"
	"mime"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
)

//go:embed all:www
var assets embed.FS

func main() {
	mime.AddExtensionType(".mjs", "text/javascript")
	mime.AddExtensionType(".wasm", "application/wasm")
	mime.AddExtensionType(".webmanifest", "application/manifest+json")

	sub, err := fs.Sub(assets, "www")
	if err != nil {
		fail("assets: " + err.Error())
		return
	}

	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		fail("listen: " + err.Error())
		return
	}
	url := fmt.Sprintf("http://127.0.0.1:%d/", ln.Addr().(*net.TCPAddr).Port)
	go serve(sub, ln)

	edge := findEdge()
	if edge == "" {
		fail("Microsoft Edge was not found. PaperSplit opens its UI in Edge app mode; please install Microsoft Edge.")
		return
	}

	profile := filepath.Join(os.Getenv("LOCALAPPDATA"), "PaperSplit", "EdgeProfile")
	if err := os.MkdirAll(profile, 0o755); err != nil {
		fail("profile: " + err.Error())
		return
	}

	cmd := exec.Command(edge,
		"--app="+url,
		"--user-data-dir="+profile,
		"--no-first-run",
		"--no-default-browser-check",
		"--disable-background-mode",
		"--window-size=1280,860",
	)
	if err := cmd.Start(); err != nil {
		fail("start Edge: " + err.Error())
		return
	}
	_ = cmd.Wait()
}

func serve(sub fs.FS, ln net.Listener) {
	files := http.FileServer(http.FS(sub))
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		p := strings.TrimPrefix(path.Clean("/"+r.URL.Path), "/")
		if p == "" {
			p = "index.html"
		}
		if _, err := fs.Stat(sub, p); err != nil && !strings.Contains(path.Base(p), ".") {
			r.URL.Path = "/"
		}
		files.ServeHTTP(w, r)
	})
	_ = http.Serve(ln, handler)
}

func findEdge() string {
	candidates := []string{
		filepath.Join(os.Getenv("ProgramFiles(x86)"), "Microsoft", "Edge", "Application", "msedge.exe"),
		filepath.Join(os.Getenv("ProgramFiles"), "Microsoft", "Edge", "Application", "msedge.exe"),
		filepath.Join(os.Getenv("LOCALAPPDATA"), "Microsoft", "Edge", "Application", "msedge.exe"),
	}
	for _, candidate := range candidates {
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}
	if p, err := exec.LookPath("msedge.exe"); err == nil {
		return p
	}
	return ""
}

func fail(message string) {
	_ = os.WriteFile(filepath.Join(os.TempDir(), "PaperSplit-error.txt"), []byte(message+"\n"), 0o644)
}
