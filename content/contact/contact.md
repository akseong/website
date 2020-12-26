---
# An instance of the Contact widget.
# Documentation: https://sourcethemes.com/academic/docs/page-builder/
widget: contact
active: true

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 130

title: Contact
subtitle:

content:
  # Automatically link email and phone or display as text?
  autolink: true
  
  # Email form provider
  form: 
    provider: # formspree
    formspree:
      id: test
    netlify:
      # Enable CAPTCHA challenge to reduce spam?
      captcha: true
  
design:
  columns: '2'
  background:
    image: backgrounds/contactbeer.jpg
    image_darken: 0.7
    image_parallax: true
    image_position: center
    image_size: cover
    # text_color_light: true
  spacing:
    padding: ["200px", "150px", "400px", "150px"] # top, R, bottom, L
---
