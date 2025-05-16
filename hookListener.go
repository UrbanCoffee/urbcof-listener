package main

import (
	"fmt"
	"os"
	"os/exec"
	"log"
	"net/http"
	"strings"

	"github.com/joho/godotenv"
	"github.com/go-playground/webhooks/v6/github"
)

const (
	path = "/webhooks"
)

func handlePush(push github.PushPayload) {
	fmt.Printf("%+v\n", push)
	if(push.Ref != "refs/heads/main") {
		return
	}

	// call script
	cmd := exec.Command("OnPush.sh")
	if err != nil {
		log.Println("Failed to call OnPush.sh script")
		return
	}
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	hook, _ := github.New(github.Options.Secret(os.Getenv("SECRET")))

	http.HandleFunc("/hook", func(res http.ResponseWriter, req *http.Request) {
		res.Header().Set("Connection", "close")

		payload, err := hook.Parse(req, github.PushEvent, github.PingEvent)
		if err != nil {
			if err == github.ErrEventNotFound {
				res.WriteHeader(http.StatusNoContent)
			} else {
				res.WriteHeader(http.StatusForbidden)
			}
			return
		}

		switch payload.(type) {
			case github.PushPayload:
				push := payload.(github.PushPayload)
				res.WriteHeader(http.StatusAccepted)
				handlePush(push)
			case github.PingPayload:
				res.WriteHeader(http.StatusOK)
				res.Write([]byte("pong"))
		}
	})
	log.Fatal(http.ListenAndServe(":" + os.Getenv("PORT"), nil))
}
