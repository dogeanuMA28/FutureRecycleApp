
.pragma library

// FutureRecycle simulated operational health calculator.

function evaluate(station, tickets) {
    if (!station || !station.bins) {
        return {
            score: 0,
            label: "Unavailable",
            color: "#94A3B8",
            statusPenalty: 0,
            capacityPenalty: 0,
            ticketPenalty: 0,
            openTickets: 0
        }
    }

    // 1. Station availability
    var statusPenalty =
        station.status === "Offline" ? 55 :
        station.status === "Maintenance" ? 28 : 0

    // 2. Container capacity
    var bins = station.bins

    var levels = [
        Number(bins.plastic) || 0,
        Number(bins.paper) || 0,
        Number(bins.metal) || 0
    ]

    var worstFill = Math.max.apply(null, levels)

    var nearFull = levels.filter(function(level) {
        return level >= 80
    }).length

    var capacityPenalty =
        worstFill >= 95 ? 25 :
        worstFill >= 80 ? 14 :
        worstFill >= 60 ? 5 : 0

    capacityPenalty += Math.max(0, nearFull - 1) * 4

    // 3. Unresolved maintenance tickets
    var ticketPenalty = 0
    var openTickets = 0
    var rows = tickets || []

    for (var i = 0; i < rows.length; i++) {
        var ticket = rows[i]

        if (ticket.stationId !== station.id)
            continue

        if (ticket.status !== "Open" &&
            ticket.status !== "In Progress")
            continue

        openTickets++

        ticketPenalty +=
            ticket.priority === "High" ? 15 :
            ticket.priority === "Medium" ? 9 : 5
    }

    ticketPenalty = Math.min(30, ticketPenalty)

    // 4. Final health score
    var score = Math.max(
        0,
        Math.min(
            100,
            100 - statusPenalty -
                  capacityPenalty -
                  ticketPenalty
        )
    )

    var label =
        score >= 85 ? "Healthy" :
        score >= 60 ? "Needs attention" :
                      "Critical"

    var color =
        score >= 85 ? "#34D399" :
        score >= 60 ? "#FBBF24" :
                      "#FB7185"

    return {
        score: score,
        label: label,
        color: color,

        statusPenalty: statusPenalty,
        capacityPenalty: capacityPenalty,
        ticketPenalty: ticketPenalty,
        openTickets: openTickets
    }
}
