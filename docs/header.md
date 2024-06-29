
{% set img_base =  img_base | default('img/') %}
{% import 'macros.j2' as macros -%}
{% set subtitle = subtitle | default("") %}
{% set subtitle = subtitle and "&nbsp; // &nbsp; <strong>" + subtitle + "</strong>" %}
<table align=center style="width:100%">
  <tr>
    <td colspan=2><strong>k8s-tools {{subtitle}}</strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td align=center width=10%>
      <center>
        <img src={{img_base}}/docker.png style="width:75px"><br/>
        <img src={{img_base}}/kubernetes.png style="width:75px"><br/>
        <img src={{img_base}}/make.png style="width:75px"><br/>
      </center>
    </td>
    <td width=90%>
      <table align=center border=1>
        <tr align=center>{%include "mini-toc.md"%}</tr>
      </table>
      <hr style="border-bottom:1px solid black;"><center><span align=center>{% include "badges.md" %}</span></center><hr style="border-bottom:1px solid black;">
    </td>
  </tr>
</table><center><span align=center>Completely dockerized version of a kubernetes toolchain, plus a zero-dependency automation framework for extending and interacting it.  Project-local clusters, customized TUIs, and more.</span></center><hr style="border-bottom:1px solid black;">

