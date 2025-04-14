#!/bin/bash

# Durée de la simulation en secondes
simulation_duration=1

# Taille des paquets en octets (fixe à 1500)
L_OCTETS=1500

# Convertir la taille des paquets en bits
L_BITS=$((L_OCTETS * 8))

# Adresse IP du serveur iPerf
server_ip="192.168.137.1"

# Nom du fichier CSV de sortie
csvFile="iperf_results.csv"

# Clean
rm ./$csvFile

# Ajouter un en-tête au fichier CSV si nécessaire
if [ ! -f "$csvFile" ]; then
    # echo "Packet_Arrival_Rate,Packets_Sent,Packets_Received,Throughput_Mbps,Throughput_PPS,Jitter,Lost_Packets" > "$csvFile"
    echo "Arrival Rate (pps),Simulation Duration (s),Flow Direction,Packets Sent,Packets Received,Throughput,Throughput (pps),Jitter,Lost_Packets" > "$csvFile"
fi

# Boucle sur les taux d'arrivée des paquets de 100 à 50_000 par pas de 1_000
for P in {100..50000..1000}
do
    # Calculer le débit en bps
    BPS=$((P * L_BITS))
    MBPS=$(echo "scale=3; $BPS / 1000000" | bc)

    # Afficher le débit calculé
    echo "Débit calculé : $BPS bps (${MBPS} Mbps) pour un taux d'arrivée de $P paquets/sec"

    # Exécuter iPerf3 et récupérer les résultats en format JSON
    result=$(iperf3 --client "$server_ip" --udp --bitrate "${MBPS}M" --length "$L_OCTETS" --time "$simulation_duration" --json)

    # Extraire les informations nécessaires du résultat JSON
    packets_sent=$(echo "$result" | jq '.end.sum.packets')
    packets_received=$(echo "$result" | jq '.end.sum.packets')
    throughput=$(echo "$result" | jq '.end.sum.bits_per_second')
    jitter=$(echo "$result" | jq '.end.sum.jitter_ms')
    lost_packets=$(echo "$result" | jq '.end.sum.lost_packets')

    # Calculer le throughput en Mbps
    throughput_Mbps=$(echo "scale=3; $throughput / 1000000" | bc)

    # Calculer le throughput en PPS (paquets par seconde)
    throughput_PPS=$((packets_sent / simulation_duration))

    # Ajouter les résultats au fichier CSV avec le taux d'arrivée des paquets
    echo "$P,$simulation_duration,STA1->AP,$packets_sent,$packets_received,$throughput_Mbps,$throughput_PPS,$jitter,$lost_packets" >> "$csvFile"

    # Pause avant la prochaine simulation
    sleep 2
done

echo "Simulation terminée. Résultats enregistrés dans $csvFile"
