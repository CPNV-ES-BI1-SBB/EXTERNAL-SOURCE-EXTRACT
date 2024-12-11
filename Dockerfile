# Utilise une image Ruby officielle
FROM ruby:3.2

# Définit le répertoire de travail
WORKDIR /app

# Copie les fichiers de configuration des gems
COPY Gemfile*  ./

# Installe les dépendances spécifiées dans le Gemfile
RUN bundle install

# Copie le reste des fichiers de l'application
COPY . .

# Définit la commande par défaut
CMD ["ruby", "main.rb"]