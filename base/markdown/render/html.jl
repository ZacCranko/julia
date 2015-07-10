# This file is a part of Julia. License is MIT: http://julialang.org/license

include("rich.jl")

# Utils

function withtag(f, io::IO, tag, attrs...)
    print(io, "<$tag")
    for (attr, value) in attrs
        print(io, " ")
        htmlesc(io, attr)
        print(io, "=\"")
        htmlesc(io, value)
        print(io, "\"")
    end
    f == nothing && return print(io, " />")

    print(io, ">")
    f()
    print(io, "</$tag>")
end

tag(io::IO, tag, attrs...) = withtag(nothing, io, tag, attrs...)

const _htmlescape_chars = Dict('<'=>"&lt;",   '>'=>"&gt;",
                               '"'=>"&quot;", '&'=>"&amp;",
                               # ' '=>"&nbsp;",
                               )
for ch in "'`!@\$\%()=+{}[]"
    _htmlescape_chars[ch] = "&#$(Int(ch));"
end

function htmlesc(io::IO, s::String)
    # s1 = replace(s, r"&(?!(\w+|\#\d+);)", "&amp;")
    for ch in s
        print(io, get(_htmlescape_chars, ch, ch))
    end
end
function htmlesc(io::IO, s::Symbol)
    htmlesc(io, string(s))
end
function htmlesc(io::IO, xs::Union{String, Symbol}...)
    for s in xs
        htmlesc(io, s)
    end
end
function htmlesc(s::Union{String, Symbol})
    sprint(htmlesc, s)
end

# Block elements

function html(io::IO, content::Vector)
    for md in content
        html(io, md)
        println(io)
    end
end

html(io::IO, md::MD) = html(io, md.content)

function html{l}(io::IO, header::Header{l})
    withtag(io, "h$l") do
        htmlinline(io, header.text)
    end
end

function html(io::IO, code::Code)
    withtag(io, :pre) do
        maybe_lang = code.language != "" ? Any[:class=>"language-$(code.language)"] : []
        withtag(io, :code, maybe_lang...) do
            htmlesc(io, code.code)
            # TODO should print newline if this is longer than one line ?
        end
    end
end

function html(io::IO, md::Paragraph)
    withtag(io, :p) do
        htmlinline(io, md.content)
    end
end

function html(io::IO, md::BlockQuote)
    withtag(io, :blockquote) do
        println(io)
        html(io, md.content)
    end
end

function html(io::IO, md::List)
    withtag(io, md.ordered ? :ol : :ul) do
        for item in md.items
            println(io)
            withtag(io, :li) do
                htmlinline(io, item)
            end
        end
        println(io)
    end
end

function html(io::IO, md::HorizontalRule)
    tag(io, :hr)
end

html(io::IO, x) = tohtml(io, x)

# Inline elements

function htmlinline(io::IO, content::Vector)
    for x in content
        htmlinline(io, x)
    end
end

function htmlinline(io::IO, code::Code)
    withtag(io, :code) do
        htmlesc(io, code.code)
    end
end

function htmlinline(io::IO, md::Union{Symbol, String})
    htmlesc(io, md)
end

function htmlinline(io::IO, md::Bold)
    withtag(io, :strong) do
        htmlinline(io, md.text)
    end
end

function htmlinline(io::IO, md::Italic)
    withtag(io, :em) do
        htmlinline(io, md.text)
    end
end

function htmlinline(io::IO, md::Image)
    tag(io, :img, :src=>md.url, :alt=>md.alt)
end

function htmlinline(io::IO, link::Link)
    withtag(io, :a, :href=>link.url) do
        htmlinline(io, link.text)
    end
end

function htmlinline(io::IO, br::LineBreak)
    tag(io, :br)
end

htmlinline(io::IO, x) = tohtml(io, x)

# API

export html

html(md) = sprint(html, md)

function writemime(io::IO, ::MIME"text/html", md::MD)
    withtag(io, :div, :class=>"markdown") do
        html(io, md)
    end
end
