## Description

Dante-Wiki is a system for taking notes and exchanging ideas, for publishing, presenting and peer reviewing. It is developed by
a scientist for scientists and students.

Dante-Wiki is based on [Mediawiki](https://www.mediawiki.org/), [LaTeX](https://www.latex-project.org/) and 
[other](#components) [open source](https://opensource.com/resources/what-open-source) components. It is deployed using Docker.
It provides data, process and workflow ownership (''sovereignty''), 
privacy and a full control over the flow of your ideas.

The current status of the system is experimental.

#### Shields

<table border=0 style="border-collapse: collapse;">
  <tr>
    <td><b>License</b></td>
    <td><a href=""><img alt="AGPL V3 license" src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg"></a></td>
  </tr>
  <tr>
    <td><b>Github</b></td>
    <td><a href=""><img alt="GitHub issues" src="https://img.shields.io/github/issues/clecap/dante-wiki"></a>&nbsp;
<a href=""><img alt="GitHub closed issues" src="https://img.shields.io/github/issues-closed/clecap/dante-wiki"></a>&nbsp;
<a href=""><img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/clecap/dante-wiki"></a>&nbsp;
<a href=""><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/m/clecap/dante-wiki"></a>&nbsp;
<a href=""><img alt="GitHub all releases" src="https://img.shields.io/github/downloads/clecap/dante-wiki/total"></a></td>
  </tr>
  <tr>
    <td><b><a href="https://github.com/clecap/dante-wiki/blob/master/.github/results/cloc_results.md" title="Show detailed line counts!">Size</a></b></td>
    <td>
      <a href="https://github.com/clecap/dante-wiki/blob/master/.github/results/cloc_results.md" title="Show detailed line counts!">
        <img alt="Repository code size" src="https://img.shields.io/github/languages/code-size/clecap/dante-wiki?color=lightgreen"></a>&nbsp;
      <a href="https://github.com/clecap/dante-wiki/actions/workflows/count_lines.yml" title="Show report on workflow execution">
        <img src="https://github.com/clecap/dante-wiki/actions/workflows/count_lines.yml/badge.svg"></a>
      <a href="https://github.com/clecap/dante-wiki/blob/master/.github/results/cloc_results.md" title="Show detailed line counts!">
        <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com/clecap/dante-wiki/master/.github/results/cloc_results.json&label=Files&query=%24.header.n_files&color=lightgreen"></a>&nbsp;
      <a href="https://github.com/clecap/dante-wiki/blob/master/.github/results/cloc_results.md" title="Show detailed line counts!">
        <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com/clecap/dante-wiki/master/.github/results/cloc_results.json&label=Lines&query=%24.header.n_lines&color=lightgreen"></a>
</td>
  </tr>
  <tr>
    <td><b><a href="https://hub.docker.com/u/clecap" title="Go to dockerhub repository">Docker</b></td>
    <td>
      <table>
      <tr>
        <td><b>Lap </b></td>
        <td>
          <a href=""><img alt="Docker Image Version" src="https://img.shields.io/docker/v/clecap/lap?sort=date&label=Pulls"></a>&nbsp;
          <a href=""><img alt="Docker Image Pulls"   src="https://img.shields.io/docker/pulls/clecap/lap"></a>&nbsp;
          <a href=""><img alt="Docker Image Size"    src="https://img.shields.io/docker/image-size/clecap/lap?sort=date&label=Size"></a>&nbsp;
          <a href=""><img alt="Docker Image Stars"   src="https://img.shields.io/docker/stars/clecap/lap"></a>&nbsp;
          <a href=""><img alt="Docker Image Build"   src="https://img.shields.io/docker/automated/clecap/lap"></a>
        </td>
      </tr>
      <tr>
        <td><b>TeX </b></td>
        <td>
          <a href=""><img alt="Docker Image Version" src="https://img.shields.io/docker/v/clecap/tex?sort=date&label=Pulls"></a>&nbsp;
          <a href=""><img alt="Docker Image Pulls"   src="https://img.shields.io/docker/pulls/clecap/tex"></a>&nbsp;
          <a href=""><img alt="Docker Image Size"    src="https://img.shields.io/docker/image-size/clecap/tex?sort=date&label=Size"></a>&nbsp;
          <a href=""><img alt="Docker Image Stars"   src="https://img.shields.io/docker/stars/clecap/tex"></a>&nbsp;
          <a href=""><img alt="Docker Image Build"   src="https://img.shields.io/docker/automated/clecap/tex"></a>
        </td>
      </tr>
      <tr>
        <td><b>Dante-Mysql </b></td>
        <td>
          <a href=""><img alt="Docker Image Version" src="https://img.shields.io/docker/v/clecap/dante-mysql?sort=date&label=Pulls"></a>&nbsp;
          <a href=""><img alt="Docker Image Pulls"   src="https://img.shields.io/docker/pulls/clecap/dante-mysql"></a>&nbsp;
          <a href=""><img alt="Docker Image Size"    src="https://img.shields.io/docker/image-size/clecap/dante-mysql?sort=date&label=Size"></a>&nbsp;
          <a href=""><img alt="Docker Image Stars"   src="https://img.shields.io/docker/stars/clecap/dante-mysql"></a>&nbsp;
          <a href=""><img alt="Docker Image Build"   src="https://img.shields.io/docker/automated/clecap/dante-mysql"></a>
        </td>
      </tr>
      </table>
    </td>
  </tr>
  <tr>
     <td><b>Security</b></td>
     <td>
       <a href="https://github.com/clecap/dante-wiki/blob/master/doc/sbom.json"><img src="https://img.shields.io/badge/SBOM-available-brightgreen?label=SBOM%20of%20lap">
      <a href=""><img src="https://github.com/clecap/dante-wiki/actions/workflows/github-code-scanning/codeql/badge.svg">
  <img src="https://github.com/clecap/dante-wiki/actions/workflows/docker-scan.yml/badge.svg">
<img src="https://github.com/clecap/dante-wiki/actions/workflows/scorecard.yml/badge.svg">
<!-- [![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/{owner}/clecap/badge)](https://scorecard.dev/viewer/?uri=github.com/clecap/dante-wiki) --!>
    </td>
  </tr>
</table>



### <a name="components"></a>Software Components and Supply Chain

Notable open source software components bundled with Dante-Wiki comprise:
* Mediawiki
* Mysql
* PHP
* LaTeX (TexLive variant)
* Drawio
* PyMuPDF

We follow the trends towards a more transparent and hopefully more secure software supply chain
and include a full Software Bill of Material (SBOM) and accredited tests into our project:

[![Scorecard supply-chain security](https://github.com/clecap/dante-wiki/actions/workflows/scorecard.yml/badge.svg)](https://github.com/clecap/dante-wiki/actions/workflows/scorecard.yml)

