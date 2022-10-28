macro pagination_before_after (table)
  if env.params.query["after"]?
    where << "#{{{table}}}.id > #{nqm.next}"
    bindings << env.params.query["after"]?
  end
  if env.params.query["before"]?
    where << "#{{{table}}}.id < #{nqm.next}"
    bindings << env.params.query["before"]?
  end
end

macro pagination_offset_limit ()
  bindings << page.offset
  bindings << page.perpage + 1
  query += " OFFSET #{nqm.next} LIMIT #{nqm.next}"
end