#!/bin/bash
# Page title (change as desired)
PAGE_TITLE="🚀 Running Docker Services"
# Host URL
HOST_URL="https://serverdomain"
# Output file
OUTPUT_FILE="/home/user/docker/portainer/html/index.html"
# Update time in minutes (when elapsed time exceeds this, the page will refresh)
UPDATE_TIME_MIN=1

# Capture the current time in ISO 8601 format (UTC) and a human-readable local time
CURRENT_TIME_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CURRENT_TIME_READABLE=$(date +"%Y-%m-%d %H:%M:%S")

# Get running containers with their names, status, and published ports
CONTAINERS=$(docker ps --format '{{.Names}}|{{.Status}}|{{.Ports}}')

# Start the HTML file
cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <!-- Prevent caching so auto-refresh fetches a fresh copy -->
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$PAGE_TITLE</title>
  <style>
    /* Import Google Font */
    @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap');

    body { 
      font-family: 'Roboto', Arial, sans-serif; 
      background-color: #f0f2f5; 
      margin: 0; 
      padding: 20px; 
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    h1 { 
      color: #333; 
      margin-bottom: 20px; 
    }

    .table-container { 
      width: 100%; 
      max-width: 1000px; 
      overflow-x: auto; 
      box-shadow: 0 4px 8px rgba(0,0,0,0.1);
      border-radius: 8px;
      background-color: #fff;
    }

    table { 
      width: 100%; 
      border-collapse: collapse; 
      border-radius: 8px; 
      overflow: hidden;
    }

    th, td { 
      padding: 12px 15px; 
      text-align: left; 
    }

    th { 
      background-color: #4CAF50; 
      color: white; 
      position: sticky;
      top: 0;
      z-index: 2;
    }

    tr:nth-child(even) { 
      background-color: #f9f9f9; 
    }

    tr:hover { 
      background-color: #f1f1f1; 
      transition: background-color 0.3s ease;
    }

    a { 
      color: #1a73e8; 
      text-decoration: none; 
      padding: 5px 10px;
      border: 1px solid #1a73e8;
      border-radius: 4px;
      transition: background-color 0.3s, color 0.3s;
      display: inline-block;
      margin: 2px 0;
    }

    a:hover { 
      background-color: #1a73e8; 
      color: white; 
    }

    .status {
      display: flex;
      align-items: center;
      font-weight: 500;
    }

    .status.running::before {
      content: '🟢';
      margin-right: 8px;
    }

    /* Paused containers show a yellow dot */
    .status.paused::before {
      content: '🟡';
      margin-right: 8px;
    }

    .status.exited::before {
      content: '🔴';
      margin-right: 8px;
    }
    
    .status.offline::before {
      content: '🔴';
      margin-right: 8px;
    }

    .update-info {
      margin-top: 20px;
      text-align: center;
      color: #555;
    }

    .update-info p {
      margin: 5px 0;
    }

    /* Responsive adjustments */
    @media screen and (max-width: 600px) {
      body { padding: 10px; }
      th, td { padding: 10px; }
      a { padding: 4px 8px; font-size: 14px; }
    }
  </style>
</head>
<body>
  <h1>$PAGE_TITLE</h1>
  <div class="table-container">
    <table>
      <thead>
        <tr>
          <th>Container Name</th>
          <th>Status</th>
          <th>Exposed Ports</th>
        </tr>
      </thead>
      <tbody>
EOF

# Function to determine the status class
get_status_class() {
    # Use a case-insensitive check for "paused"
    if [[ "$1" =~ [Pp]aused ]]; then
        echo "paused"
    elif [[ "$1" == *"Up"* ]]; then
        echo "running"
    else
        echo "exited"
    fi
}

# Process each container from the docker ps output
while IFS='|' read -r NAME STATUS PORTS; do
    PORT_LINKS=""
    if [[ -n "$PORTS" ]]; then
        declare -A unique_ports
        IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
        for PORT_MAPPING in "${PORT_ARRAY[@]}"; do
            # Trim any extra spaces
            PORT_MAPPING=$(echo "$PORT_MAPPING" | xargs)
            # Match patterns like ":8080->" or ":8080-8081->"
            if [[ "$PORT_MAPPING" =~ :([0-9]+)(-([0-9]+))?\-\> ]]; then
                start=${BASH_REMATCH[1]}
                end=${BASH_REMATCH[3]}
                if [[ -n "$end" ]]; then
                    for port in $(seq $start $end); do
                        if [[ "$port" =~ ^[0-9]+$ ]] && [[ -z "${unique_ports[$port]}" ]]; then
                            unique_ports[$port]=1
                            PORT_LINKS+="<a href='${HOST_URL}:$port' target='_blank'>$port</a> "
                        fi
                    done
                else
                    port=$start
                    if [[ "$port" =~ ^[0-9]+$ ]] && [[ -z "${unique_ports[$port]}" ]]; then
                        unique_ports[$port]=1
                        PORT_LINKS+="<a href='${HOST_URL}:$port' target='_blank'>$port</a> "
                    fi
                fi
            fi
        done
    else
        PORT_LINKS="N/A"
    fi

    STATUS_CLASS=$(get_status_class "$STATUS")
    CLEAN_STATUS=$(echo "$STATUS" | awk -F',' '{print $1}')

    echo "        <tr>
          <td>$NAME</td>
          <td class='status $STATUS_CLASS'>$CLEAN_STATUS</td>
          <td>$PORT_LINKS</td>
        </tr>" >> "$OUTPUT_FILE"
done <<< "$CONTAINERS"

# Append the remaining HTML (including cookie logic for offline containers and refresh logic)
cat <<EOF >> "$OUTPUT_FILE"
      </tbody>
    </table>
  </div>
  
  <div class="update-info">
    <p>Last Updated: <span id="last-updated">$CURRENT_TIME_READABLE</span></p>
    <p>Time since last update: <span id="time-since">0 seconds</span></p>
  </div>

  <script>
    // Use the generated timestamp as the reference point for refresh logic
    const lastUpdatedStr = "$CURRENT_TIME_ISO";
    const lastUpdated = new Date(lastUpdatedStr);
    // Update time in minutes for auto-refresh (set by bash variable)
    const updateTimeMin = $UPDATE_TIME_MIN;

    function updateElapsedTime() {
      const now = new Date();
      const diff = Math.floor((now - lastUpdated) / 1000); // difference in seconds

      let seconds = diff % 60;
      let minutes = Math.floor(diff / 60) % 60;
      let hours = Math.floor(diff / 3600) % 24;
      let days = Math.floor(diff / 86400);

      let elapsedStr = '';
      if (days > 0) elapsedStr += days + ' day' + (days > 1 ? 's ' : ' ');
      if (hours > 0) elapsedStr += hours + ' hour' + (hours > 1 ? 's ' : ' ');
      if (minutes > 0) elapsedStr += minutes + ' minute' + (minutes > 1 ? 's ' : ' ');
      elapsedStr += seconds + ' second' + (seconds !== 1 ? 's' : '');

      document.getElementById('time-since').textContent = elapsedStr;

      // When auto-refresh is triggered, force a full reload bypassing cache
      if (diff >= updateTimeMin * 60) {
          window.location.href = window.location.pathname + '?_=' + new Date().getTime();
      }
    }

    // Cookie utility functions to store container names
    function getCookie(name) {
      const matches = document.cookie.match(new RegExp(
        "(?:^|; )" + name.replace(/([\\.$?*|{}()\\[\\]\\\\\\/\\+^])/g, '\\\\$1') + "=([^;]*)"
      ));
      return matches ? decodeURIComponent(matches[1]) : null;
    }

    function setCookie(name, value, options = {}) {
      options = { path: '/', ...options };
      let updatedCookie = encodeURIComponent(name) + "=" + encodeURIComponent(value);
      for (let optionKey in options) {
        updatedCookie += "; " + optionKey;
        let optionValue = options[optionKey];
        if (optionValue !== true) {
          updatedCookie += "=" + optionValue;
        }
      }
      document.cookie = updatedCookie;
    }

    // Update table to include offline containers from stored cookie data
    function updateOfflineContainers() {
      let containerCookie = getCookie("containers");
      let storedContainers = [];
      if (containerCookie) {
        try {
          storedContainers = JSON.parse(containerCookie);
        } catch(e) {
          storedContainers = [];
        }
      }
      
      let table = document.querySelector("table tbody");
      let currentContainers = [];
      table.querySelectorAll("tr").forEach(row => {
        let containerName = row.querySelector("td").textContent.trim();
        if (containerName) {
          currentContainers.push(containerName);
        }
      });
      
      // Merge current container names with those stored previously
      storedContainers = Array.from(new Set([...storedContainers, ...currentContainers]));
      let offlineContainers = storedContainers.filter(name => !currentContainers.includes(name));
      
      // Append rows for any offline containers
      offlineContainers.forEach(name => {
        let row = document.createElement("tr");
        row.innerHTML = \`
          <td>\${name}</td>
          <td class="status offline">Offline</td>
          <td>N/A</td>\`;
        table.appendChild(row);
      });
      
      // Update the cookie for one year
      setCookie("containers", JSON.stringify(storedContainers), { "max-age": 31536000 });
    }

    updateElapsedTime();
    updateOfflineContainers();
    setInterval(updateElapsedTime, 1000);
  </script>
</body>
</html>
EOF

echo "🎉 HTML file generated with update timestamp: $CURRENT_TIME_READABLE"
