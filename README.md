# WordPress SQLite FrankenPHP, Caddy Docker Environment

A Docker-based development environment built on top of **FrankenPHP**, configured to run **WordPress with SQLite support**, and served using **Caddy**.

---

## Getting Started

Follow these steps to spin up the development environment locally.

### 1. Copy Environment Variables

Create your `.env` file from the provided template:

```bash
cat env-test.txt > .env
```

### 2. Start the Docker Environment

Run the following command to build and start the container in detached mode:

```bash
docker compose up -d
```

### 3. Access the Application

Once the container is running, open your browser and navigate to:

```txt
https://localhost/
```

## Notes

- HTTPS is enabled via Caddy, so your browser may prompt a security warning on first access.

## Managing WordPress Plugins

WordPress plugins are managed via wp-packages.org a composer based package manager. You should add required plugins to the `./build-dependancies/composer.json` file.

Local plugin archives can be placed in `./build-dependancies/plugins` and will be installed into `./public/wp-content/plugins` during the build process.

## Local Dependencies

Local development dependency configuration files are located in the `./local` folder.
