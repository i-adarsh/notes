Shopify

sudo apt update -y

sudo apt-get install xdg-utils snapd -y

sudo snap install ngrok -y

curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update \
  && sudo apt install ngrok

  ngrok config add-authtoken 33kPvkR2haJGTQETjWX8Ls5Ln3N_47qJ47WDZo4fvdYJTS7As

  ngrok http 3000


  shopify app dev --tunnel-url=https://<ngrok-URL>:3000
