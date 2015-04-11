<img src='http://python-bitstring.googlecode.com/svn/trunk/doc/bitstring_logo.png' width='250'>

A Python module that makes the creation, manipulation and analysis of binary data as simple and natural as possible.<br>
<br>
Bitstrings can be constructed from integers, floats, hex, octal, binary, bytes or files. They can also be created and interpreted using flexible format strings.<br>
<br>
Bitstrings can be sliced, joined, reversed, inserted into, overwritten, etc. with simple methods or using slice notation. They can also be read from, searched and replaced, and navigated in, similar to a file or stream.<br>
<br>
Internally the bit data is efficiently stored in byte arrays, the module has been optimized for speed, and excellent code coverage is given by over 400 unit tests.<br>
<br>
Written by <a href='mailto:dr.scottgriffiths@gmail.com'>Scott Griffiths</a> and released under a permissive open source licence for you to use however you like.<br>
<br>
<hr />
<h1>News</h1>

<h2><font color='#4444cc'>March 4th 2014:</font> <font color='green'>Version 3.1.3 released</font></h2>

This is a bug fix release.<br>
<br>
<ul><li>Fix for problem with prepend for bitstrings with byte offsets in their data store (<a href='https://code.google.com/p/python-bitstring/issues/detail?id=141'>Issue 141</a>).</li></ul>


For details of earlier changes see the <a href='http://packages.python.org/bitstring/release_notes.html'>Release Notes</a>.<br>
<br>
<hr />

<h2><font color='#4444cc'>Download</font></h2>

Get the latest version from PyPI, either <a href='http://pypi.python.org/pypi/bitstring/'>directly</a> or via easy_install / pip.<br>
<hr />

<h2><font color='#4444cc'>Documentation</font></h2>

<a href='http://packages.python.org/bitstring'>Latest documentation</a>

Some quick links to useful parts of the docs:<br>
<br>
<ul><li><a href='http://packages.python.org/bitstring/walkthrough.html'>Brief Walkthrough</a>
</li><li><a href='http://packages.python.org/bitstring/creation.html'>Bitstring Creation and Interpretation</a>
</li><li><a href='http://packages.python.org/bitstring/reading.html'>Reading, Parsing and Unpacking</a>
</li><li><a href='http://packages.python.org/bitstring/quick_ref.html'>Module Quick Reference</a>
</li><li><a href='http://packages.python.org/bitstring/reference.html'>Full Module Reference</a></li></ul>


<hr />

<h2><font color='#4444cc'>Examples</font></h2>

See the <a href='Examples.md'>Wiki</a> and the <a href='http://packages.python.org/bitstring/examples.html'>user manual</a> for more examples.<br>
<br>
Creation:<br>
<pre><code>&gt;&gt;&gt; a = BitArray('0b00101')    # 5 bits long<br>
&gt;&gt;&gt; b = Bits(a_file_object)     # Treat file as array of bits.<br>
&gt;&gt;&gt; c = BitArray('0xff, 0b101, 0o65, uint:6=22')   # Many initialisers joined together<br>
&gt;&gt;&gt; d = pack('intle:16, hex=a, 0b1', 100, a='0x34f') # Create using bit-wise pack function<br>
&gt;&gt;&gt; e = pack('&lt;16h', *range(16))<br>
</code></pre>
Different interpretations, slicing and concatenation:<br>
<pre><code>&gt;&gt;&gt; a = BitArray('0x1af')<br>
&gt;&gt;&gt; a.hex, a.bin, a.uint     # Different interpretations using properties<br>
('1af', '000110101111', 431)<br>
&gt;&gt;&gt; a[10:3:-1].bin           # Slice with negative step<br>
'1110101'<br>
&gt;&gt;&gt; 3*a + 'int:20=40'<br>
BitArray('0x1af1af1af00028')<br>
</code></pre>

Reading data sequentially.<br>
<pre><code>&gt;&gt;&gt; b = BitStream('0x160120f')<br>
&gt;&gt;&gt; b.read('hex:12')           # Read 12 bits, and interpret as hex<br>
'160'<br>
&gt;&gt;&gt; b.pos = 0<br>
&gt;&gt;&gt; b.read('uint:12')          # Read those same bits, but interpret as integer<br>
352<br>
&gt;&gt;&gt; b.readlist('uint:12, bin:3')  # Multiple reads<br>
[288, '111']<br>
</code></pre>

Searching, inserting and deleting:<br>
<pre><code>&gt;&gt;&gt; c = BitStream('0b00010010010010001111')   # c.hex == '1248f'<br>
&gt;&gt;&gt; c.find('0x48')    # Note that found byte wasn't byte-aligned<br>
True<br>
&gt;&gt;&gt; c.replace('0b001', '0xabc')  # Replace all 3-bit occurrences with 12-bits<br>
&gt;&gt;&gt; c.insert('0b0000')<br>
&gt;&gt;&gt; del c[4:12]<br>
</code></pre>
<hr />
Developed with the help of<br>
<br>
<a href='http://www.jetbrains.com/pycharm'><img src='http://python-bitstring.googlecode.com/svn/wiki/pycharm_logo.gif' width='170></a'>