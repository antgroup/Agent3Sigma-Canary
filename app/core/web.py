from flask import current_app, render_template

def render_site(status=200):
    catalog = current_app.extensions['site_modules'].catalog()
    return render_template('home.html', catalog=catalog), status
