require 'parslet'
require "offside_rule/version"

module OffsideRule
  class OffsideParser < Parslet::Parser

    def initialize(indent_mode: :spaces, indent_width: 2)
      super()
      @indent_mode = indent_mode
      @indent_width = indent_width
      @on_content_handler = default_content_handler
    end

    def default_content_handler
      -> * { match['^\s'].repeat(1).as(:content) }
    end

    def set_content_handler(handler=Proc.new)
      tap { @on_content_handler = handler }
    end

    def on_content
      instance_eval(&@on_content_handler)
    end

    def indent_char
      case @indent_mode
      when :tab
        "\t"
      when :space
        " " * @indent_width
      end
    end

    def indent(depth)
      str(indent_char * depth)
    end

    rule(:newline) { str("\n") }

    rule(:content) { on_content }

    def line(depth)
      indent(depth) >>
      content >>
      newline.maybe
    end

    rule(:blankline) { (match[' \t'].repeat >> newline) }

    def node(depth)
      (
        blankline.maybe >>
        indent(depth) >>
        content >>
        newline.maybe >>
        (dynamic{|s,c| node(depth+1).repeat(0)}).as(:children)
      )
    end

    rule(:document) { (blankline | node(0)).repeat }

    root :document
  end

end
