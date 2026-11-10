<?php
/* Template Name: Campaign Landing Page */
get_header();
?>
<main class="campaign-page">
  <?php the_content(); ?>
  <?php echo do_shortcode('[legacy_lead_form campaign="atlas-launch"]'); ?>
</main>
<?php get_footer(); ?>

