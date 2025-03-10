# Utiliser une image Node.js de base
FROM node:16-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers nécessaires
COPY package*.json ./
COPY . .

# Installer les dépendances
RUN npm install --production

# Exposer le port de l'application
EXPOSE 3000

# Lancer l'application
CMD ["npm", "start"]
