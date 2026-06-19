package cineflow

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// Config for CineFlow client
type Config struct {
	APIURL string
	APIKey string
}

// Client for CineFlow API
type Client struct {
	apiURL string
	apiKey string
	http   *http.Client
}

// NewClient creates a new CineFlow client
func NewClient(config Config) *Client {
	return &Client{
		apiURL: config.APIURL,
		apiKey: config.APIKey,
		http:   &http.Client{},
	}
}

// CreateExperience creates a new experience
func (c *Client) CreateExperience(title, description string) (map[string]interface{}, error) {
	payload := map[string]string{
		"title":       title,
		"description": description,
	}
	return c.post("/api/v1/experiences", payload)
}

// GetExperience retrieves an experience
func (c *Client) GetExperience(experienceID string) (map[string]interface{}, error) {
	return c.get(fmt.Sprintf("/api/v1/experiences/%s", experienceID))
}

func (c *Client) post(path string, data interface{}) (map[string]interface{}, error) {
	body, _ := json.Marshal(data)
	req, _ := http.NewRequest("POST", c.apiURL+path, bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", c.apiKey)
	
	resp, _ := c.http.Do(req)
	defer resp.Body.Close()
	
	respBody, _ := io.ReadAll(resp.Body)
	var result map[string]interface{}
	json.Unmarshal(respBody, &result)
	return result, nil
}

func (c *Client) get(path string) (map[string]interface{}, error) {
	req, _ := http.NewRequest("GET", c.apiURL+path, nil)
	req.Header.Set("X-API-Key", c.apiKey)
	
	resp, _ := c.http.Do(req)
	defer resp.Body.Close()
	
	respBody, _ := io.ReadAll(resp.Body)
	var result map[string]interface{}
	json.Unmarshal(respBody, &result)
	return result, nil
}
