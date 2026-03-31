# GitHub Metrics Dashboard

Stop losing your repository traffic data.

GitHub only shows views, clones, and referrers for the last 14 days. Want to see trends from last month? You can't.

This dashboard solves that.

## What it does

- Archives everything – daily snapshots of views, clones, and referrers
- Stores forever – all data saved as CSV in your own private repo
- Generates charts – beautiful trend graphs using ruby-libgd (no JavaScript!)
- Runs automatically – GitHub Actions does the work daily
- Live dashboard – auto-deploys to GitHub Pages

## Live Demo

ruby-libgd
https://ggerman.github.io/github-metrics-dashboard/ruby-libgd_views_trend.png

libgd-gis
https://ggerman.github.io/github-metrics-dashboard/libgd-gis_views_trend.png

Live dashboard: https://ggerman.github.io/github-metrics-dashboard

## Quick Start (5 minutes)

1. Clone this repository

2. Edit config.yml with your repositories:
   owner: your_username
   name: your_repo
   display_name: My Project

3. Create a GitHub token with repo scope

4. Add secrets to your repository:
   GH_TOKEN = your token
   METRICS_VAULT_TOKEN = same token

5. Enable GitHub Pages (Settings -> Pages -> Source: GitHub Actions)

6. Run workflows from Actions tab:
   Archive Metrics -> Run workflow
   Generate Dashboard -> Run workflow

## Results

Your dashboard will be live at:
https://your-username.github.io/github-metrics-dashboard

## Real data from my repositories

ruby-libgd: 469 views, 119 clones, +68% WoW
libgd-gis: 332 views, 232 clones, +110% WoW

## Built with

- ruby-libgd – pure Ruby chart generation
- Octokit – GitHub API client
- GitHub Actions – automation
- GitHub Pages – hosting

## License

MIT

## Author

German A. Gimenez Silva
ggerman@gmail.com
https://github.com/ggerman

Your metrics should be yours forever. Now they are.