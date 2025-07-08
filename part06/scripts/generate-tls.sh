#!/bin/bash

domain=$1

nomad tls ca create -name-constraint="true" -domain "$domain" -additional-domain "$domain"
nomad tls cert create -server -region global -domain "$domain" -additional-dnsname "$domain"
nomad tls cert create -client -ca "$domain-agent-ca.pem" -key "$domain-agent-ca-key.pem" -additional-dnsname "$domain"
nomad tls cert create -cli -ca "$domain-agent-ca.pem" -key "$domain-agent-ca-key.pem" -additional-dnsname "$domain"