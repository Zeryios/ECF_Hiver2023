# Utiliser une image Node.js officielle
FROM node:18


# Copier les fichiers de l'application
COPY package*.json ./
COPY app.js ./

# Installer les dépendances (aucune dans cet exemple, mais important si besoin)
RUN npm install

# Exposer le port que l'application utilise
EXPOSE 80

# Commande pour lancer l'application
CMD ["node", "app.js"]
