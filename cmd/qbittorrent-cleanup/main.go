// Package main provides a utility to manage errored torrents in qBittorrent.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// Torrent represents the structure of a qBittorrent torrent object.
type Torrent struct {
	Hash  string `json:"hash"`
	State string `json:"state"`
	Name  string `json:"name"`
}

// QBitClient abstracts the qBittorrent API interactions.
type QBitClient struct {
	BaseURL string
	HTTP    *http.Client
}

var rootCmd = &cobra.Command{
	Use:   "qbittorrent-cleanup",
	Short: "Removes missingFiles torrents and resumes recoverable errored torrents",
	Run:   runCleanup,
}

func init() {
	f := rootCmd.Flags()
	f.String("url", "", "qBittorrent WebUI URL")
	f.String("user", "", "qBittorrent username")
	f.String("password", "", "qBittorrent password")
	f.Duration("timeout", 30*time.Second, "API request timeout")

	cobra.OnInitialize(func() {
		viper.SetEnvPrefix("QBT")
		viper.AutomaticEnv()
		_ = viper.BindPFlags(f)
	})
}

func NewClient(baseURL string) (*QBitClient, error) {
	jar, err := cookiejar.New(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create cookie jar: %w", err)
	}
	return &QBitClient{
		BaseURL: strings.TrimSuffix(baseURL, "/"),
		HTTP:    &http.Client{Jar: jar},
	}, nil
}

func (c *QBitClient) Login(ctx context.Context, user, pass string) error {
	data := url.Values{"username": {user}, "password": {pass}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+"/api/v2/auth/login", strings.NewReader(data.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }() // Fix: ignored error explicitly

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("login failed: %d", resp.StatusCode)
	}
	return nil
}

func (c *QBitClient) GetErroredTorrents(ctx context.Context) ([]Torrent, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.BaseURL+"/api/v2/torrents/info?filter=error", http.NoBody)
	if err != nil {
		return nil, err
	}

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, err
	}
	defer func() { _ = resp.Body.Close() }() // Fix: ignored error explicitly

	var torrents []Torrent
	if err := json.NewDecoder(resp.Body).Decode(&torrents); err != nil {
		return nil, err
	}
	return torrents, nil
}

func (c *QBitClient) DeleteTorrents(ctx context.Context, hashes []string) error {
	data := url.Values{"hashes": {strings.Join(hashes, "|")}, "deleteFiles": {"true"}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+"/api/v2/torrents/delete", strings.NewReader(data.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }() // Fix: ignored error explicitly
	return nil
}

func (c *QBitClient) Resume(ctx context.Context, hashes []string) error {
	data := url.Values{"hashes": {strings.Join(hashes, "|")}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+"/api/v2/torrents/start", strings.NewReader(data.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }() // Fix: ignored error explicitly
	return nil
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

func runCleanup(_ *cobra.Command, _ []string) { // Fix: Rename 'cmd' to '_'
	apiURL := viper.GetString("url")
	user := viper.GetString("user")
	pass := viper.GetString("password")
	timeout := viper.GetDuration("timeout")

	if apiURL == "" || user == "" || pass == "" {
		log.Fatal("Error: Missing required configuration (URL, User, or Password)")
	}

	client, err := NewClient(apiURL)
	if err != nil {
		log.Fatalf("Client error: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	// Logic fix: Don't use log.Fatalf inside runCleanup if you want defers to run.
	// Or accept that the process dies immediately. Since this is a CLI tool,
	// Fatalf is okay, but we should handle the 'Auth error' properly.

	if err := client.Login(ctx, user, pass); err != nil {
		fmt.Printf("Auth error: %v\n", err)
		return // Using return ensures defer cancel() runs
	}

	torrents, err := client.GetErroredTorrents(ctx)
	if err != nil {
		fmt.Printf("Fetch error: %v\n", err)
		return
	}

	var toDelete []string
	var toResume []string

	for _, t := range torrents {
		if t.State == "missingFiles" {
			fmt.Printf("Found missing files for: %s\n", t.Name)
			toDelete = append(toDelete, t.Hash)
		} else {
			toResume = append(toResume, t.Hash)
		}
	}

	if len(toDelete) > 0 {
		fmt.Printf("Deleting %d torrents with missing files...\n", len(toDelete))
		if err := client.DeleteTorrents(ctx, toDelete); err != nil {
			log.Printf("Delete error: %v", err)
		}
	}

	if len(toResume) > 0 {
		fmt.Printf("Resuming %d recoverable torrents...\n", len(toResume))
		if err := client.Resume(ctx, toResume); err != nil {
			log.Printf("Resume error: %v", err)
		}
	}

	if len(toDelete) == 0 && len(toResume) == 0 {
		fmt.Println("No action needed.")
	} else {
		fmt.Println("Cleanup complete.")
	}
}
