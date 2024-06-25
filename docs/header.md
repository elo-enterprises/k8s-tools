{% set img_base =  img_base | default('img/') %}
<table style="width:100%">
  <tr>
    <td colspan=2><strong>
    k8s-tools
      </strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td width=10%>
      <center>
        <img src={{img_base}}/docker.png style="width:75px"><br/>
        <img src={{img_base}}/kubernetes.png style="width:75px"><br/>
        <img src={{img_base}}/make.png style="width:75px"><br/>
      </center>
    </td>
    <td>
      Completely dockerized version of a kubernetes toolchain, plus a zero-dependency automation framework for extending and interacting it.
      <br/>
      <p align="center">
        <table width="100%" border=1><tr>
          <td><a href=/README.md#overview>Overview</a></td>
          <td><a href=/README.md#features>Features</a></td>
          <td><a href=/README.md#integration>Integration</a></td>
          <td><a href=/README.md#composemk>compose.mk</a></td>
          <td><a href=/README.md#k8smk>k8s.mk</a></td>
          <td><a href=/docs/api.md>API</a></td>
          <td><a href=/docs/demos.md>Demos</a></td>
        </tr>
        <tr><td colspan="100%">
          {%for action in github.actions%}<a href="{{action.url}}"><img src="{{action.url}}/badge.svg"></a>{%endfor%}
        </td></tr></table>
      </p><br/>
    </td>
  </tr>
</table>

