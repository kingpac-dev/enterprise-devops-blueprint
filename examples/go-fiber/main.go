package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

type Order struct {
	ID        string    `json:"id"`
	Customer  string    `json:"customer"`
	Amount    float64   `json:"amount"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

func SetupApp() *fiber.App {
	app := fiber.New(fiber.Config{
		DisableStartupMessage: true,
		ReadTimeout:           10 * time.Second,
		WriteTimeout:          10 * time.Second,
	})

	app.Use(recover.New())

	// Liveness Probe: Confirms the process is running
	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status": "healthy",
			"time":   time.Now().UTC().Format(time.RFC3339),
		})
	})

	// Readiness Probe: Confirms dependencies are healthy
	app.Get("/readyz", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status":   "ready",
			"database": "connected",
		})
	})

	// Metrics endpoint (Prometheus format placeholder)
	app.Get("/metrics", func(c *fiber.Ctx) error {
		metricsText := "# HELP orders_processed_total Total number of orders processed\n" +
			"# TYPE orders_processed_total counter\n" +
			"orders_processed_total 42\n"
		c.Set("Content-Type", "text/plain; version=0.0.4")
		return c.SendString(metricsText)
	})

	// Sample business endpoint
	api := app.Group("/api/v1")
	api.Get("/orders", func(c *fiber.Ctx) error {
		orders := []Order{
			{
				ID:        "ord-1001",
				Customer:  "Acme Corp",
				Amount:    250.75,
				Status:    "Confirmed",
				CreatedAt: time.Now().UTC().Add(-1 * time.Hour),
			},
			{
				ID:        "ord-1002",
				Customer:  "Global Logistics",
				Amount:    1420.00,
				Status:    "Processing",
				CreatedAt: time.Now().UTC(),
			},
		}
		return c.JSON(orders)
	})

	return app
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	app := SetupApp()

	// Graceful shutdown channel
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		log.Println("[INFO] Shutting down Go Fiber server gracefully...")
		_ = app.Shutdown()
	}()

	log.Printf("[INFO] Orders API (Go Fiber) listening on port %s...", port)
	if err := app.Listen(":" + port); err != nil {
		log.Printf("[INFO] Server stopped: %v", err)
	}
}
