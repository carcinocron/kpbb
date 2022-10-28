# @link https://crystal-lang.org/reference/syntax_and_semantics/annotations.html

annotation Kpbb::Orm::Column
end
annotation Kpbb::Orm::Table
end

macro select_from
  {% if @type.annotation(Kpbb::Orm::Table)[:alias] %}
    "SELECT #{self.select} FROM {{ @type.annotation(Kpbb::Orm::Table)[:alias] }} as {{@type.annotation(Kpbb::Orm::Table)[:alias]}}"
  {% else %}
    "SELECT #{self.select} FROM {{ @type.annotation(Kpbb::Orm::Table)[:alias] }}"
  {% end %}
end

macro orm_get_columns_for_select
  arr = Array(String).new
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% for ivar in cols %}
    {% if ann = ivar.annotation(Kpbb::Orm::Column) %}
      arr << {{ ivar.stringify }}
    {% end %}
  {% end %}
  arr
end

macro orm_define_init_from_rs
  self.new(
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% for ivar, index in cols %}{% if ann = ivar.annotation(Kpbb::Orm::Column) %}
    {{ ivar.name }}: rs.read({{ ivar.type }}){% if index + 1 != cols.size %},{% else %}){% end %}
  {% end %}{% end %}
end

# from scoped variables, create a new instance of this struct/class
# shortcut for self.new(id: id, handle: handle)
macro init_from_column_vars
  self.new(
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% for ivar, index in cols %}{% if ann = ivar.annotation(Kpbb::Orm::Column) %}
    {{ ivar.name }}: {{ ivar.name }}{% if index + 1 != cols.size %},{% else %}){% end %}
  {% end %}{% end %}
end

macro orm_define_insert
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% cols_returning = cols.select { |c| c.annotation(Kpbb::Orm::Column)[:insert_return] == true } %}
  {% cols_inserting = cols.select { |c| c.annotation(Kpbb::Orm::Column)[:insert] != false } %}
  {% cols_binding = cols_inserting.select { |c| !c.annotation(Kpbb::Orm::Column)[:insert] } %}
  {% qm_index = 0 %}
  query = <<-SQL
    INSERT INTO #{@@table} (
      {% for ivar, index in cols_inserting %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
        {{ ivar.name }}{% if index + 1 != cols_inserting.size %},{% else %}){% end %}
      {% end %}{% end %}
    VALUES (
      {% for ivar, index in cols_inserting %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
        /*{{ ivar.name }}*/ {% if ann[:insert] %}{{ ann[:insert].id }}{% else %}${{ (qm_index += 1) }}{% ann[:insert] %}{% end %}{% if index + 1 != cols_inserting.size %},{% else %}){% end %}
      {% end %}{% end %}
    {% for ivar, index in cols_returning %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
      {% if index == 0 %}returning{% end %}
      {{ ivar.name }}{% if index + 1 != cols_returning.size %},{% else %}{% end %}
    {% end %}{% end %}
  SQL
  {% for ivar, index in cols_returning %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
    {{ ivar.name }}{% if index + 1 != cols_returning.size %},{% else %} ={% end %}
  {% end %}{% end %} Kpbb.db.query_one(query, args: [
    {% for ivar, index in cols %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) && ann[:insert] != false && !(ann[:insert]) %}
      insertable[:{{ ivar.name }}],
    {% end %}{% end %}
  ], as:
    {% for ivar, index in cols_returning %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
      {% if cols_returning.size > 1 && index == 0 %}\{{% end %}
        {{ ivar.type }}{% if index + 1 != cols_returning.size %},{% end %} # {{ ivar.stringify }}
      {% if cols_returning.size > 1 && index + 1 == cols_returning.size %}}{% end %}
    {% end %}{% end %}
  )
  self.new(
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% for ivar, index in cols %}{% if ann = ivar.annotation(Kpbb::Orm::Column) %}
    {{ ivar.name }}: {% if ann[:insert_return] == true %}{{ ivar.name }}{% else %}insertable[:{{ ivar.name }}]{% end %}{% if index + 1 != cols.size %},{% else %}){% end %}
  {% end %}{% end %}
end

macro orm_define_upsert
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% cols_returning = cols.select { |c| c.annotation(Kpbb::Orm::Column)[:insert_return] == true } %}
  {% cols_upserting = cols.select { |c| c.annotation(Kpbb::Orm::Column)[:insert] != false } %}
  {% cols_binding = cols_upserting.select { |c| !c.annotation(Kpbb::Orm::Column)[:insert] } %}
  {% cols_composite_keys = cols_upserting.select { |c| c.annotation(Kpbb::Orm::Column)[:upsert_key] == true } %}
  {% cols_excluded = cols_upserting.select { |c| c.annotation(Kpbb::Orm::Column)[:upsert_excluded] != false }.select { |c| c.annotation(Kpbb::Orm::Column)[:upsert_key] != true } %}
  {% qm_index = 0 %}
  query = <<-SQL
    INSERT INTO #{@@table} (
      {% for ivar, index in cols_upserting %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
        {{ ivar.name }}{% if index + 1 != cols_upserting.size %},{% else %}){% end %}
      {% end %}{% end %}
    VALUES (
      {% for ivar, index in cols_upserting %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
        /*{{ ivar.name }}*/ {% if ann[:insert] %}{{ ann[:insert].id }}{% else %}${{ (qm_index += 1) }}{% ann[:insert] %}{% end %}{% if index + 1 != cols_upserting.size %},{% else %}){% end %}
      {% end %}{% end %}
    ON CONFLICT (
      {% for ivar, index in cols_composite_keys %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
        {{ ivar.name }}{% if index + 1 != cols_composite_keys.size %},{% else %}{% end %}
      {% end %}{% end %}
    ) DO UPDATE SET
      {% for ivar, index in cols_excluded %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
        {{ ivar.name }} = excluded.{{ ivar.name }}{% if index + 1 != cols_excluded.size %},{% else %}{% end %}
      {% end %}{% end %}
    {% for ivar, index in cols_returning %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
      {% if index == 0 %}returning{% end %}
      {{ ivar.name }}{% if index + 1 != cols_returning.size %},{% else %}{% end %}
    {% end %}{% end %}
  SQL
  {% for ivar, index in cols_returning %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
    {{ ivar.name }}{% if index + 1 != cols_returning.size %},{% else %} ={% end %}
  {% end %}{% end %} Kpbb.db.query_one(query, args: [
    {% for ivar, index in cols %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) && ann[:insert] != false && !(ann[:insert]) %}
      upsertable[:{{ ivar.name }}],
    {% end %}{% end %}
  ], as:
    {% for ivar, index in cols_returning %}{% if (ann = ivar.annotation(Kpbb::Orm::Column)) %}
      {% if cols_returning.size > 1 && index == 0 %}\{{% end %}
        {{ ivar.type }}{% if index + 1 != cols_returning.size %},{% end %} # {{ ivar.stringify }}
      {% if cols_returning.size > 1 && index + 1 == cols_returning.size %}}{% end %}
    {% end %}{% end %}
  )
  self.new(
  {% cols = @type.instance_vars.select(&.annotation(Kpbb::Orm::Column)) %}
  {% for ivar, index in cols %}{% if ann = ivar.annotation(Kpbb::Orm::Column) %}
    {{ ivar.name }}: {% if ann[:insert_return] == true %}{{ ivar.name }}{% else %}upsertable[:{{ ivar.name }}]{% end %}{% if index + 1 != cols.size %},{% else %}){% end %}
  {% end %}{% end %}
end

macro use_orm
  @[AlwaysInline]
  def self.init_from_rs(rs : DB::ResultSet) : self
    orm_define_init_from_rs
  end

  def self.select_columns : Array(String)
    orm_get_columns_for_select
  end

  def self.insert!(**insertable) : self
    orm_define_insert
  end

  def self.save!(**insertable) : self
    orm_define_insert
  end
end

macro use_orm_upsert
  @[AlwaysInline]
  def self.init_from_rs(rs : DB::ResultSet) : self
    orm_define_init_from_rs
  end

  def self.select_columns : Array(String)
    orm_get_columns_for_select
  end

  def self.upsert!(**upsertable) : self
    orm_define_upsert
  end

  # def self.save!(**upsertable) : self
  #   orm_define_upsert
  # end
end
