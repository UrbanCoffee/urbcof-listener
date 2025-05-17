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
	if(push.Ref != "refs/heads/main") {
		return
	}

	// check if changes occured in frontend or backend
	fe_path := os.Getenv("FRONT_NAME")
	be_path := os.Getenv("BACK_NAME")
	fe_change := false
	be_change := false

	// expecting commit to be squashed
	changes := append(push.Commits[0].Added, push.Commits[0].Removed...)
	changes = append(changes, push.Commits[0].Modified...) 
	for _, change := range changes {
		fe_change = fe_change || strings.HasPrefix(change, fe_path)
		be_change = be_change || strings.HasPrefix(change, be_path)
		if(fe_change && be_change) {break}
	}

	args := []string{}
	if(fe_change) {args = append(args, "FRONTEND")}
	if(be_change) {args = append(args, "BACKEND"  )}

	// call script
	cmd := exec.Command("./OnPush.sh", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin  = os.Stdin
	if err := cmd.Run(); err != nil {
		fmt.Printf("Failed to run script. Reason:\n%s\n", err)
		fmt.Println("================")
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
				go handlePush(push)
			case github.PingPayload:
				res.WriteHeader(http.StatusOK)
				res.Write([]byte("pong"))
		}
	})
	log.Fatal(http.ListenAndServe(":" + os.Getenv("PORT"), nil))
}
