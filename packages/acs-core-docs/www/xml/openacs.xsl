<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:doc="http://nwalsh.com/xsl/documentation/1.0"
		version="1.1"
                exclude-result-prefixes="doc">

<!-- vinodk: This stylesheet simply imports chunk.xsl                   -->
<!-- I'll add customization later                                       -->

  <xsl:import href="/usr/share/sgml/docbook/stylesheet/xsl/nwalsh/html/chunk.xsl"/>
  <xsl:output media-type="text/html" encoding="iso-8859-1"/>


  <xsl:variable name="toc.section.depth">1</xsl:variable>
  <xsl:variable name="using.chunker">1</xsl:variable>
  <xsl:variable name="use.id.as.filename">1</xsl:variable>

  <xsl:variable name="chunk.first.sections">1</xsl:variable>
  
  <xsl:template name="header.navigation">
	<xsl:param name="prev" select="/foo"/>
	<xsl:param name="next" select="/foo"/>
	<xsl:variable name="home" select="/*[1]"/>
	<xsl:variable name="up" select="parent::*"/>

	<xsl:if test="$suppress.navigation = '0'">
	  <div class="navheader">
		<a href="http://openacs.org"><img src="images/alex.jpg" border="0" /></a>
		<table width="100%" summary="Navigation header" border="0">
		  <tr>
			<td width="20%" align="left">
			  <xsl:if test="count($prev)>0">
				<a accesskey="p">
				  <xsl:attribute name="href">
					<xsl:call-template name="href.target">
					  <xsl:with-param name="object" select="$prev"/>
					</xsl:call-template>
				  </xsl:attribute>
				  <xsl:call-template name="gentext.nav.prev"/>
				</a>
			  </xsl:if>
			  <xsl:text><![CDATA[&nbsp;]]></xsl:text>
			</td>
			<th width="60%" align="center">
			  <xsl:choose>
				<xsl:when test="count($up) > 0 and $up != $home">
				  <xsl:apply-templates select="$up" mode="object.title.markup"/>
				</xsl:when>
				<xsl:otherwise><![CDATA[&nbsp;]]></xsl:otherwise>
			  </xsl:choose>
			</th>
			<td width="20%" align="right">
			  <xsl:text><![CDATA[&nbsp;]]></xsl:text>
			  <xsl:if test="count($next)>0">
				<a accesskey="n">
				  <xsl:attribute name="href">
					<xsl:call-template name="href.target">
					  <xsl:with-param name="object" select="$next"/>
					</xsl:call-template>
				  </xsl:attribute>
				  <xsl:call-template name="gentext.nav.next"/>
				</a>
			  </xsl:if>
			</td>
		  </tr>
		</table>
		<hr/>
	  </div>
	</xsl:if>
  </xsl:template>
  
  
  <xsl:template name="footer.navigation">
	<xsl:param name="prev" select="/foo"/>
	<xsl:param name="next" select="/foo"/>
	<xsl:variable name="home" select="/*[1]"/>
	<xsl:variable name="up" select="parent::*"/>
	
	<xsl:if test="$suppress.navigation = '0'">
	  <div class="navfooter">
		<hr/>
		<table width="100%" summary="Navigation footer">
		  <tr>
			<td width="40%" align="left">
			  <xsl:if test="count($prev)>0">
				<a accesskey="p">
				  <xsl:attribute name="href">
					<xsl:call-template name="href.target">
					  <xsl:with-param name="object" select="$prev"/>
					</xsl:call-template>
				  </xsl:attribute>
				  <xsl:call-template name="gentext.nav.prev"/>
				</a>
			  </xsl:if>
			  <xsl:text><![CDATA[&nbsp;]]></xsl:text>
			</td>
			<td width="20%" align="center">
			  <xsl:choose>
				<xsl:when test="$home != .">
				  <a accesskey="h">
					<xsl:attribute name="href">
					  <xsl:call-template name="href.target">
						<xsl:with-param name="object" select="$home"/>
					  </xsl:call-template>
					</xsl:attribute>
					<xsl:call-template name="gentext.nav.home"/>
				  </a>
				</xsl:when>
				<xsl:otherwise><![CDATA[&nbsp;]]></xsl:otherwise>
			  </xsl:choose>
			</td>
			<td width="40%" align="right">
			  <xsl:text><![CDATA[&nbsp;]]></xsl:text>
			  <xsl:if test="count($next)>0">
				<a accesskey="n">
				  <xsl:attribute name="href">
					<xsl:call-template name="href.target">
					  <xsl:with-param name="object" select="$next"/>
					</xsl:call-template>
				  </xsl:attribute>
				  <xsl:call-template name="gentext.nav.next"/>
				</a>
			  </xsl:if>
			</td>
		  </tr>
		  
		  <tr>
			<td width="40%" align="left">
			  <xsl:apply-templates select="$prev" mode="object.title.markup"/>
			  <xsl:text><![CDATA[&nbsp;]]></xsl:text>
			</td>
			<td width="20%" align="center">
			  <xsl:choose>
				<xsl:when test="count($up)>0">
				  <a accesskey="u">
					<xsl:attribute name="href">
					  <xsl:call-template name="href.target">
						<xsl:with-param name="object" select="$up"/>
					  </xsl:call-template>
					</xsl:attribute>
					<xsl:call-template name="gentext.nav.up"/>
				  </a>
				</xsl:when>
				<xsl:otherwise><![CDATA[&nbsp;]]></xsl:otherwise>
			  </xsl:choose>
			</td>
			<td width="40%" align="right">
			  <xsl:text><![CDATA[&nbsp;]]></xsl:text>
			  <xsl:apply-templates select="$next" mode="object.title.markup"/>
			</td>
		  </tr>
		</table>
		<hr/>
		<address>
			rmello at fslc.usu.edu
		</address>
		<address>
		  <a>
			<xsl:attribute name="href">
			  <xsl:text>mailto:vinod@kurup.com</xsl:text>
			</xsl:attribute>
			vinod@kurup.com
		  </a>
		</address>
	  </div>
	</xsl:if>
  </xsl:template>
  
  <xsl:template match="authorblurb">
	<div class="{name(.)}">
	  <xsl:apply-templates/>
	</div>
  </xsl:template>
  
  
  <xsl:template name="html.head">
	<xsl:param name="prev" select="/foo"/>
	<xsl:param name="next" select="/foo"/>
	<xsl:variable name="home" select="/*[1]"/>
	<xsl:variable name="up" select="parent::*"/>
	
	<head>
	  <xsl:call-template name="head.content"/>
	  <xsl:call-template name="user.head.content"/>
	  
	  <xsl:if test="$home">
		<link rel="home">
		  <xsl:attribute name="href">
			<xsl:call-template name="href.target">
			  <xsl:with-param name="object" select="$home"/>
			</xsl:call-template>
		  </xsl:attribute>
		  <xsl:attribute name="title">
			<xsl:apply-templates select="$home"
			  mode="object.title.markup.textonly"/>
		  </xsl:attribute>
		</link>
	  </xsl:if>
	  
	  <xsl:if test="$up">
		<link rel="up">
		  <xsl:attribute name="href">
			<xsl:call-template name="href.target">
			  <xsl:with-param name="object" select="$up"/>
			</xsl:call-template>
		  </xsl:attribute>
		  <xsl:attribute name="title">
			<xsl:apply-templates select="$up" mode="object.title.markup.textonly"/>
		  </xsl:attribute>
		</link>
	  </xsl:if>
	  
	  <xsl:if test="$prev">
		<link rel="previous">
		  <xsl:attribute name="href">
			<xsl:call-template name="href.target">
			  <xsl:with-param name="object" select="$prev"/>
			</xsl:call-template>
		  </xsl:attribute>
		  <xsl:attribute name="title">
			<xsl:apply-templates select="$prev" mode="object.title.markup.textonly"/>
		  </xsl:attribute>
		</link>
	  </xsl:if>
	  
	  <xsl:if test="$next">
		<link rel="next">
		  <xsl:attribute name="href">
			<xsl:call-template name="href.target">
			  <xsl:with-param name="object" select="$next"/>
			</xsl:call-template>
		  </xsl:attribute>
		  <xsl:attribute name="title">
			<xsl:apply-templates select="$next" mode="object.title.markup.textonly"/>
		  </xsl:attribute>
		</link>
	  </xsl:if>

	  <link rel="stylesheet" href="openacs.css" type="text/css">
	  </link>

	</head>
  </xsl:template>

<!-- make phrase a "div" tag instead of "span" -->
  <xsl:template match="phrase">
	<div>
	  <xsl:if test="@role and $phrase.propagates.style != 0">
		<xsl:attribute name="class">
		  <xsl:value-of select="@role"/>
		</xsl:attribute>
	  </xsl:if>
	  <xsl:call-template name="anchor"/>
	  <xsl:apply-templates/>
	</div>
  </xsl:template>

</xsl:stylesheet>
