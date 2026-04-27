// Package main provides a utility to resume errored torrents in qBittorrent.
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

// Torrent represents the basic structure of a qBittorrent torrent object.
type Torrent struct {
	Hash string `json:"hash"`
}

// QBitClient abstracts the qBittorrent API interactions.
type QBitClient struct {
	BaseURL string
	HTTP    *http.Client
}

// rootCmd is the base command when called without any subcommands.
var rootCmd = &cobra.Command{
	Use:   "qbittorrent-resume",
	Short: "Resumes errored torrents in qBittorrent",
	Run:   runResume,
}

func init() {
	// 1. Define CLI Flags
	f := rootCmd.Flags()
	f.String("url", "", "qBittorrent WebUI URL (e.g. http://localhost:8080)")
	f.String("user", "", "qBittorrent username")
	f.String("password", "", "qBittorrent password")
	f.Duration("timeout", 30*time.Second, "API request timeout")

	// 2. Initialize Viper Configuration
	cobra.OnInitialize(func() {
		viper.SetEnvPrefix("QBT")
		viper.AutomaticEnv()

		// Bind all flags to Viper keys
		if err := viper.BindPFlags(rootCmd.Flags()); err != nil {
			log.Fatalf("Error binding flags: %v", err)
		}
	})
}

// NewClient initializes a new qBittorrent client with a cookie jar.
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

// Login authenticates with the qBittorrent Web UI.
func (c *QBitClient) Login(ctx context.Context, user, pass string) error {
	data := url.Values{"username": {user}, "password": {pass}}
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.BaseURL+"/api/v2/auth/login",
		strings.NewReader(data.Encode()),
	)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("login failed with status: %d", resp.StatusCode)
	}
	return nil
}

// GetErroredHashes fetches hashes of torrents currently in an error state.
func (c *QBitClient) GetErroredHashes(ctx context.Context) ([]string, error) {
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		c.BaseURL+"/api/v2/torrents/info?filter=errored",
		http.NoBody,
	)
	if err != nil {
		return nil, err
	}

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, err
	}
	defer func() { _ = resp.Body.Close() }()

	var torrents []Torrent
	if err := json.NewDecoder(resp.Body).Decode(&torrents); err != nil {
		return nil, err
	}

	hashes := make([]string, len(torrents))
	for i, t := range torrents {
		hashes[i] = t.Hash
	}
	return hashes, nil
}

// Resume sends a start command to the specified torrent hashes.
func (c *QBitClient) Resume(ctx context.Context, hashes []string) error {
	data := url.Values{"hashes": {strings.Join(hashes, "|")}}
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.BaseURL+"/api/v2/torrents/start",
		strings.NewReader(data.Encode()),
	)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("resume failed with status: %d", resp.StatusCode)
	}
	return nil
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

func runResume(cmd *cobra.Command, _ []string) {
	apiURL := viper.GetString("url")
	user := viper.GetString("user")
	pass := viper.GetString("password")
	timeout := viper.GetDuration("timeout")

	if apiURL == "" || user == "" || pass == "" {
		_ = cmd.Usage()
		log.Fatal("\nError: Missing required configuration (URL, User, or Password)")
	}

	client, err := NewClient(apiURL)
	if err != nil {
		log.Fatalf("Client error: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	fmt.Println("Logging in...")
	if err := client.Login(ctx, user, pass); err != nil {
		log.Printf("Auth error: %v", err)
		return
	}

	fmt.Println("Checking for errored torrents...")
	hashes, err := client.GetErroredHashes(ctx)
	if err != nil {
		log.Printf("Fetch error: %v", err)
		return
	}

	if len(hashes) == 0 {
		fmt.Println("No errored torrents found.")
		return
	}

	fmt.Printf("Resuming %d torrents...\n", len(hashes))
	if err := client.Resume(ctx, hashes); err != nil {
		log.Printf("Resume error: %v", err)
		return
	}

	fmt.Println("Start command sent successfully.")
}
