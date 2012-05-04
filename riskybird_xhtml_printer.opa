module RegexpXhtmlPrinter {
  function xhtml pretty_print(option(regexp) parsed_regexp) {
    match (parsed_regexp) {
      case {none}:
        <>
          <div class="alert-message error">
            <strong>oh snap!</strong> Parsing failed!
          </div>
        </>
      case {some: x}:
        <>
          <div class="pp">
            {print_simple_list(x)}
          </div>
          <br style="clear: both"/>
          <div>{Debug.dump(parsed_regexp)}</div>
        </>
     }
  }

  function xhtml join(list(xhtml) l, xhtml glue) {
    match (l) {
      case []: <></>
      case [x]: x
      case {~hd, ~tl}: <>{hd}{glue}{join(tl, glue)}</>
    }
  }

  function xhtml print_simple_list(regexp regexp) {
    t = List.map(
      print_basic_list,
      regexp)
    r = join(t, <hr/>)

    <div class="print_simple_list">{r}</div>
  }

  function xhtml print_basic_list(simple simple) {
    t = List.fold(
      function (basic, r) {
        <>
          {r}
          {print_basic(basic)}
        </>
      },
      simple,
      <></>
    )
    <div class="noborder print_basic_list">{t}</div>
  }

  function xhtml print_basic(basic basic) {
    <span class="print_basic">
      {print_postfix(basic.bpost)}
      {print_elementary(basic.belt)}
    </span>
  }

  function xhtml print_elementary(elementary elementary) {
    match (elementary) {
      case {edot}: <b>.</b>
      case {~echar}: <>{echar}</>
      case {escaped_char:x}: <>{"\\{x}"}</>
      case {~group_id, ~egroup}:
        <span class="print_elementary">
          <span class="mylabel"><span>group {group_id}</span></span>{print_simple_list(egroup)}
        </span>
      case {~eset}: <>{print_set(eset)}</>
    }
  }

  function print_set(rset set) {
    t = List.fold(
      function(item, r) {
        i = match (item) {
          case {~iechar}: <>\\{iechar}</>
          case {~ichar}: <>{ichar}</>
          case {~irange}: <>{irange.rstart}-{irange.rend}</>
        }
        <>
          {r}
          {i}
        </>
      },
      set.items,
      <></>
    )
    if (set.neg) {
      <>[^{t}]</>
    } else {
      <>[{t}]</>
    }
  }

  function xhtml print_postfix(postfix) {
    match (postfix) {
      case {noop}: <></>
      case {star}: <span class="mylabel"><span>N</span></span>
      case {plus}: <span class="mylabel"><span>1-N</span></span>
      case {qmark}: <span class="mylabel"><span>0-1</span></span>
      case {exact: x}: <span class="mylabel"><span>{x}</span></span>
      case {at_least: x}: <span class="mylabel"><span>{x}-N</span></span>
      case {~min, ~max}: <span class="mylabel"><span>{min}-{max}</span></span>
    }
  }
}
