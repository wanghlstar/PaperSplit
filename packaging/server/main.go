package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"mime"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

const version = "1.0.0"

func main() {
	root := flag.String("root", "www", "directory containing the built web app")
	host := flag.String("host", "0.0.0.0", "listen host")
	port := flag.String("port", "15100", "listen port (0 picks a free port)")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		return
	}

	// fnOS injects the configured service port as TRIM_SERVICE_PORT.
	if envPort := os.Getenv("TRIM_SERVICE_PORT"); envPort != "" && !flagSet("port") {
		*port = envPort
	}

	absRoot, err := filepath.Abs(*root)
	if err != nil {
		log.Fatalf("resolve root: %v", err)
	}
	if info, err := os.Stat(absRoot); err != nil || !info.IsDir() {
		log.Fatalf("root directory not found: %s", absRoot)
	}

	mime.AddExtensionType(".mjs", "text/javascript; charset=utf-8")
	mime.AddExtensionType(".wasm", "application/wasm")
	mime.AddExtensionType(".webmanifest", "application/manifest+json")

	listener, err := net.Listen("tcp", net.JoinHostPort(*host, *port))
	if err != nil {
		log.Fatalf("listen: %v", err)
	}
	actualPort := listener.Addr().(*net.TCPAddr).Port
	fmt.Printf("LISTENING %d\n", actualPort)
	os.Stdout.Sync()

	server := &http.Server{
		Handler:           withHeaders(spaHandler(absRoot)),
		ReadHeaderTimeout: 10 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		errCh <- server.Serve(listener)
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-errCh:
		if err != nil && err != http.ErrServerClosed {
			log.Fatalf("serve: %v", err)
		}
	case sig := <-stop:
		log.Printf("received %s, shutting down", sig)
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(ctx)
	}
}

func flagSet(name string) bool {
	found := false
	flag.Visit(func(f *flag.Flag) {
		if f.Name == name {
			found = true
		}
	})
	return found
}

func withHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}

func spaHandler(root string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		clean := path.Clean("/" + r.URL.Path)
		filePath := filepath.Join(root, filepath.FromSlash(clean))

		info, err := os.Stat(filePath)
		if err == nil && !info.IsDir() {
			http.ServeFile(w, r, filePath)
			return
		}
		if err == nil && info.IsDir() {
			index := filepath.Join(filePath, "index.html")
			if indexInfo, indexErr := os.Stat(index); indexErr == nil && !indexInfo.IsDir() {
				http.ServeFile(w, r, index)
				return
			}
			http.NotFound(w, r)
			return
		}

		// Fall back to index.html for client-side routes without a file extension.
		if !strings.Contains(path.Base(clean), ".") {
			index := filepath.Join(root, "index.html")
			if _, indexErr := os.Stat(index); indexErr == nil {
				http.ServeFile(w, r, index)
				return
			}
		}
		http.NotFound(w, r)
	})
}
