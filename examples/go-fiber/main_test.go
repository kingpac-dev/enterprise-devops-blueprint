package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthCheckEndpoints(t *testing.T) {
	app := SetupApp()

	// Test /healthz (Liveness)
	reqLiveness := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	respLiveness, err := app.Test(reqLiveness, 2000)
	if err != nil {
		t.Fatalf("Failed to execute /healthz: %v", err)
	}
	if respLiveness.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200 for /healthz, got %d", respLiveness.StatusCode)
	}

	// Test /readyz (Readiness)
	reqReadiness := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	respReadiness, err := app.Test(reqReadiness, 2000)
	if err != nil {
		t.Fatalf("Failed to execute /readyz: %v", err)
	}
	if respReadiness.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200 for /readyz, got %d", respReadiness.StatusCode)
	}
}

func TestOrdersListEndpoint(t *testing.T) {
	app := SetupApp()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/orders", nil)
	resp, err := app.Test(req, 2000)
	if err != nil {
		t.Fatalf("Failed to execute /api/v1/orders: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Failed to read response body: %v", err)
	}

	var orders []Order
	if err := json.Unmarshal(body, &orders); err != nil {
		t.Fatalf("Failed to parse JSON response: %v", err)
	}

	if len(orders) != 2 {
		t.Errorf("Expected 2 orders, got %d", len(orders))
	}
}
