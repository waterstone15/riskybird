/**
 * Main web app code.
 *
 *
 *
 *   This file is part of RiskyBird
 *
 *   RiskyBird is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   RiskyBird is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with RiskyBird.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Julien Verlaguet
 * @author Alok Menghrajani
 */

import stdlib.themes.bootstrap

/**
 * Renders the main page.
 *
 * The page contains an input forms field and a few example links.
 *
 * - the svg rendering gets stuffed in #parser_output
 * - the lint results are put in #lint_output
 */
function resource display() {
  Resource.styled_page(
    "RegexpLint",
    ["/resources/riskybird.css"],
    <>
      <div id="wrap"><div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
          <div class="container">
            <a href="/" class="brand">RegexpLint</a>
          </div>
        </div>
      </div>

      <div id="main" class="container">
        <section id="info">
          <p class="lead">
            RegexpLint helps you understand and analyze regular expressions.<br/>
            We graphically render regular expressions and point out common pitfalls.
          </p>
          <p>
            Enter a regular expression or try <a onclick={function(_){set_regexp("^a.*|b$")}}>example 1</a> ·
            <a onclick={function(_){set_regexp("a(bc?|[d-e])\{4,\}f")}}>example 2</a> ·
            <a onclick={function(_){set_regexp("(abc).(efg).\\2\\4")}}>example 3</a>
          </p>
        </section>

        <section id="go">
            <div id="row1" class="row">
              <div class="span12">
                <div class="input">
                  <input
                    class="xxlarge"
                    type="text"
                    id=#regexp
                    placeholder="Enter a regular expression"
                    value=""
                    onnewline={function(_){check_regexp()}}
                  />
                  <input class="btn" type="submit" value="render & lint" style="margin-bottom: 9px"
                    onclick={function(_){check_regexp()}}/>
                </div>
                <br/>
              </div>
            </div>
            <div id="row2" class="row hidden">
              <div class="span12">
                <div class="input">
                  <span id=#string_output class="uneditable-input xxlarge"
                    onclick={function(_){Dom.add_class(#row2, "hidden"); Dom.add_class(#row3, "hidden"); Dom.remove_class(#row1, "hidden"); }}/>
                </div>
                <div id=#parser_output/>
                <div id=#debug_output style="display: none"/>
              </div>
            </div>
            <div id="row3" class="row hidden" style="margin-top: 12px">
              <div class="span4" id=#lint_output/>
              <div class="span8">&nbsp;</div>
            </div>
        </section>

        <section id="cheatsheet">
          <p class="lead">
            Use the table below as a cheat sheet:
          </p>
            <table>
              <tr>
                <td><code>[abc]</code></td>
                <td>a, b or c</td>

                <td><code>.</code></td>
                <td>any single character</td>

                <td><code>a?</code></td>
                <td>zero or one of a</td>
              </tr>
              <tr>
                <td><code>[^abc]</code></td>
                <td>any character except a, b, or c</td>

                <td><code>\\s</code></td>
                <td>whitespace</td>

                <td><code>a*</code></td>
                <td>zero or more of a</td>
              </tr>
              <tr>
                <td><code>[a-z]</code></td>
                <td>range a-z</td>

                <td><code>\\S</code></td>
                <td>non-whitespace</td>

                <td><code>a+</code></td>
                <td>one or more of a</td>
              </tr>
              <tr>
                <td><code>[a-zA-Z]</code></td>
                <td>a-z or A-Z</td>

                <td><code>\\d</code></td>
                <td>any digit</td>

                <td><code>a\{n\}</code></td>
                <td>exactly n of a</td>
              </tr>
              <tr>
                <td><code>^</code></td>
                <td>anchor at start of line</td>

                <td><code>\\D</code></td>
                <td>any non-digit</td>

                <td><code>a\{n,\}</code></td>
                <td>n or more of a</td>
              </tr>
              <tr>
                <td><code>$</code></td>
                <td>anchor at end of line</td>

                <td><code>\\w</code></td>
                <td>any word character (letter, number, underscore)</td>

                <td><code>a\{n,m\}</code></td>
                <td>between n and m of a</td>
              </tr>
              <tr>
                <td><code>(...)</code></td>
                <td>capture everything enclosed</td>

                <td><code>\\W</code></td>
                <td>any non-word character</td>

                <td><code>a*?</code></td>
                <td>zero or more of a (non greedy)</td>
              </tr>
              <tr>
                <td><code>(a|b)</code></td>
                <td>a or b</td>

                <td><code>\\b</code></td>
                <td>any word boundary</td>

                <td><code>(a)...\\1</code></td>
                <td>back reference</td>
              </tr>
              <tr>
                <td><code>(?=a)</code></td>
                <td>look ahead (positive)</td>

                <td><code>(?!a)</code></td>
                <td>look ahead (negative)</td>

                <td><code>\\B</code></td>
                <td>any non-word boundary</td>
              </tr>
            </table>
        </section>

      </div>
      <div class="push"></div>
      </div>
      {display_footer()}
    </>
  )
}

client function set_regexp(string r) {
  Dom.set_value(#regexp, r)
  check_regexp()
}

/**
 * Our nice little about page.
 */
function resource display_about() {
  Resource.styled_page(
    "RegexpLint | About",
    ["/resources/riskybird.css"],
    <>
      <div id="wrap"><div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
          <div class="container">
            <a href="/" class="brand">RegexpLint</a>
          </div>
        </div>
      </div>
      <div id="main" class="container">
        <section id="about">
          <div class="row">
            <div class="span4">&nbsp;</div>
            <div class="span8">
              <p class="lead">About</p>
              <p>
                RegexpLint was written by a few Facebook engineers on their spare
                time. The purpose of this tool is to help fellow engineers understand,
                write and audit regular expressions.
              </p>
              <p>
                Our code is written in <a href="http://www.opalang.org/">Opa</a>, a modern web framework. We decided to use
                to use this framework for various reasons, one of them being that it makes writing parsers very easy!
                We <a href="http://alokmenghrajani/riskybird/">open sourced</a> all the code to encourage people to look at it,
                improve it or build on it.
              </p>
              <p>
                What's next? Peer <a href="http://regexplint.userecho.com/">feedback</a> is going to
                help us decide what we are going to build next!
              </p>
            </div>
          </div>
          <div class="row">
            <div class="span2">&nbsp;</div>
            <div class="span2">
              <img src="http://graph.facebook.com/julien.verlaguet/picture"
                style="border: 1px solid #0E0E0E; border-radius: 3px 3px 3px 3px;
                  box-shadow: 0 8px 5px -4px rgba(0, 0, 0, 0.3);
                  margin: 12px;"/>
            </div>
            <div class="span8" style="margin-top: 12px">
              <h3>Julien Verlaguet</h3>
              <p>Wrote the parser.</p>
            </div>
          </div>
          <div class="row">
            <div class="span2">&nbsp;</div>
            <div class="span2">
              <img src="http://graph.facebook.com/erling/picture"
                style="border: 1px solid #0E0E0E; border-radius: 3px 3px 3px 3px;
                  box-shadow: 0 8px 5px -4px rgba(0, 0, 0, 0.3);
                  margin: 12px;"/>
            </div>
            <div class="span8" style="margin-top: 12px">
              <h3>Erling Ellingsen</h3>
              <p>Found bugs, helped fix them and will continue to find more.</p>
            </div>
          </div>
          <div class="row">
            <div class="span2">&nbsp;</div>
            <div class="span2">
              <img src="http://graph.facebook.com/alok/picture"
                style="border: 1px solid #0E0E0E; border-radius: 3px 3px 3px 3px;
                  box-shadow: 0 8px 5px -4px rgba(0, 0, 0, 0.3);
                  margin: 12px;"/>
            </div>
            <div class="span8" style="margin-top: 12px">
              <h3>Alok Menghrajani</h3>
              <p>Worked on the lint engine.</p>
            </div>
          </div>
        </section>
      </div>
      <div class="push"></div>
      </div>
      {display_footer()}
    </>
  )
}

/**
 * Shared footer.
 */
function xhtml display_footer() {
  <footer class="footer">
    <p>
      <a href="/about">About</a> ·
      <a href="http://www.opalang.org/">Written in Opa</a> ·
      <a href="http://github.com/alokmenghrajani/riskybird/">Fork on github.com</a> ·
      <a href="http://regexplint.userecho.com/">Provide Feedback</a>
    </p>
    <div class="social-buttons">
      <iframe src="http://www.facebook.com/plugins/like.php?href=http%3A%2F%2Fwww.facebook.com%2FRegexpLint&amp;send=false&layout=button_count&amp;width=75&amp;show_faces=false&amp;action=like&amp;colorscheme=light&amp;font&amp;height=21&amp;appId=202562833203260" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:75px; height:21px;" allowTransparency="true"></iframe>
      <span style="padding-left: 20px">&nbsp;</span>
      <a href="https://twitter.com/share" class="twitter-share-button" data-url="http://regexp.quaxio.com/" data-via="alokmenghrajani">Tweet</a>
      <script>{"!function(d,s,id)\{var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id))\{js=d.createElement(s);js.id=id;js.src='//platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);\}\}(document,'script','twitter-wjs');"}</script>
    </div>
    <script type="text/javascript">{"var _gaq=_gaq||[];_gaq.push(['_setAccount','UA-2373559-10']);_gaq.push(['_trackPageview']);(function()\{var ga=document.createElement('script');ga.type='text/javascript';ga.async=true;ga.src=('https:'==document.location.protocol?'https://ssl':'http://www')+'.google-analytics.com/ga.js';var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(ga,s);\})();"}</script>
  </footer>
}

/**
 * Runs the lint engine.
 */
function void linter_run(regexp regexp) {
  lint_result status = RegexpLinter.regexp(regexp)
  l = RegexpLinterRender.render(status)

  if (Option.is_some(l)) {
    #lint_output = Option.get(l)
  } else {
    #lint_output = <></>
  }
}

/**
 * Parses the regexp and then:
 * - renders it (using the SvgPrinter)
 * - runs it throught the lint engine
 */
client function void check_regexp() {
  Dom.add_class(#row1, "hidden")
  Dom.remove_class(#row2, "hidden")
  Dom.remove_class(#row3, "hidden")

  string regexp = Dom.get_value(#regexp)

  // easter egg
  if (regexp == "xkcd") {
    #parser_output = <img src="http://imgs.xkcd.com/comics/regular_expressions.png "/>
    #string_output = <>xkcd</>
    #lint_output = <></>
  } else {
    parsed_regexp = RegexpParser.parse(regexp)
    match (parsed_regexp) {
      case {none}:
        #string_output = <>{regexp}</>
        #parser_output =
          <div class="alert-message error">
            <strong>oh snap!</strong> Parsing failed!
          </div>
        #lint_output = <></>
      case {~some}:
        #string_output = RegexpHighlightStringPrinter.pretty_print(
          GroupRegexp.do_regexp(some, {highlight_string_printer}))
        #parser_output = RegexpSvgPrinter.pretty_print(
          GroupRegexp.do_regexp(some, {svg_printer}))
        linter_run(some)
        #debug_output = <>{Debug.dump(some)}</>
    }
  }
}

function resource start(Uri.relative uri) {
  match (uri) {
    case {path:["about"] ...}:
      display_about()
    case {path:["favicon.ico"] ...}:
      @static_resource("resources/favicon.png")
    case {...}:
      display()
  }
}

Server.start(
  Server.http,
  [
    {resources: @static_include_directory("resources")},
    {dispatch: start}
  ]
)
