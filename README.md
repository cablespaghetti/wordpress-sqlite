# wordpress-sqlite
Lightweight Wordpress on Alpine with php-fpm ondemand and SQLite instead of MySQL.

```bash
docker pull milanb/wordpress-sqlite
```
[Docker Hub milanb/wordpress-sqlite](https://hub.docker.com/r/milanb/wordpress-sqlite/)

Can be used in conjunction with [wordpress-nginx](https://github.com/milanboers/wordpress-nginx) ([Docker Hub milanb/wordpress-nginx](https://hub.docker.com/r/milanb/wordpress-nginx/)) to provide a full lightweight Wordpress solution.

Example docker-compose.yml for both:
```yaml
version: '2'
services:
    wp:
        image: milanb/wordpress-sqlite
        environment:
            - WP_HOME=https://mysite.com
            - WP_SITEURL=https://mysite.com
        volumes:
            - db:/var/www/db
            - uploads:/var/www/html/wp-content/uploads
        restart: always
    http:
        image: milanb/wordpress-nginx
        links:
            - wp:wordpress
        volumes_from:
            - wp
        ports:
            - "8081:80"
volumes:
    db:
        external: true
    uploads:
        external: true
```

## Migrating an existing website

1. Tar/Zip up the web root directory e.g. `/var/www/html`
2. Get a dump of the MySQL database for example with `mysqldump`
3. Use [mysql2sqlite](https://github.com/dumblob/mysql2sqlite) to convert your MySQL dump to a new SQLite database
4. Change the domain name in `ingress.yaml` and then apply to a new namespace with `kubectl apply -f kubernetes/`
5. When the pod is up and running, copy your backups into the container with commands like

```
kubectl cp -c wordpress db.db wordpress-0:/var/www/db/
kubectl cp -c wordpress backup.zip wordpress-0:/var/www/
```

6. You can then "exec" into the container with `kubectl exec -it -c wordpress wordpress-0 -- /bin/bash`
7. Now you're in the container you need to ensure that the database has the right owner with `chown www-data. /var/www/db/db.db`
8. Extracting the backup is a little more fiddly but you can do something like

```
rm -r *
mv ../backup.zip .
unzip backup.zip
rm backup.zip
chown -R www-data. .
```
9. You now need to modify your old Wordpress installation to use SQLite. First copy the driver PHP file to the right location with `cp /usr/src/wordpress/wp-content/db.php wp-content/`
10. You will now need to edit the wp-config.php file. You can either use `vi` in the container for this, or `kubectl cp` it out, edit it in your favourite editor and then `kubectl cp` it back in. Just make sure it is still owned by `www-data:www-data`. For my environment I had to remove the `DB_NAME`, `DB_USER`, `DB_PASSWORD` and `DB_HOST` definitions and add in the following lines

```
define('DB_FILE', 'db.db');    
define('DB_DIR', '/var/www/db/');   
```

11. Because I'm using HTTPS behind a Kubernetes Ingress I also found I had to add these lines to `wp-config` to get everything working correctly

```
// Reverse proxy https fix
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')
    $_SERVER['HTTPS'] = 'on';
if (isset($_SERVER['HTTP_X_FORWARDED_HOST']))
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
```