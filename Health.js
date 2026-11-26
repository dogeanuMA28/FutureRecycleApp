.pragma library

// Educational operational score. This is not a hardware sensor reading.
function evaluate(station, tickets) {
    if (!station || !station.bins) {
        return {
            score: 0, label: "Unavailable", color: "#94A3B8",
            statusPenalty: 0, capacityPenalty: 0, ticketPenalty: 0, openTickets: 0
        }
    }

    var statusPenalty = station.status === "Offline" ? 55
                      : station.status === "Maintenance" ? 28 : 0
    var bins = station.bins
    var levels = [Number(bins.plastic) || 0, Number(bins.paper) || 0, Number(bins.metal) || 0]
    var worst = Math.max.apply(null, levels)
    var nearFull = levels.filter(function(level) { return level >= 80 }).length
    var capacityPenalty = worst >= 95 ? 25 : worst >= 80 ? 14 : worst >= 60 ? 5 : 0
    capacityPenalty += Math.max(0, nearFull - 1) * 4

    var ticketPenalty = 0
    var openTickets = 0
    var rows = tickets || []
    for (var i = 0; i < rows.length; i++) {
        var ticket = rows[i]
        if (ticket.stationId !== station.id ||
            (ticket.status !== "Open" && ticket.status !== "In Progress"))
            continue
        openTickets++
        ticketPenalty += ticket.priority === "High" ? 15 : ticket.priority === "Medium" ? 9 : 5
    }
    ticketPenalty = Math.min(30, ticketPenalty)
    var score = Math.max(0, Math.min(100,
                    100 - statusPenalty - capacityPenalty - ticketPenalty))
    return {
        score: score,
        label: score >= 85 ? "Healthy" : score >= 60 ? "Needs attention" : "Critical",
        color: score >= 85 ? "#34D399" : score >= 60 ? "#FBBF24" : "#FB7185",
        statusPenalty: statusPenalty,
        capacityPenalty: capacityPenalty,
        ticketPenalty: ticketPenalty,
        openTickets: openTickets
    }
}
