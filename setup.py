#!/usr/bin/env python

from distutils.core import setup
from distutils.extension import Extension

use_cython = False # Set to True if you want to build from Cython source yourself

if use_cython:
    from Cython.Distutils import build_ext
else:
    from distutils.command import build_ext

import sys

kwds = {'long_description': open('README.rst').read()}

if sys.version_info[:2] < (2, 7):
    raise Exception('This version of bitstring needs Python 2.7 or Python 3.x.')

macros = [('PYREX_WITHOUT_ASSERTIONS', None)]
cmdclass = {}
if use_cython:
    print("Compiling with Cython")
    ext_modules = [Extension('_cbitstring', ["_cbitstring.pyx"], define_macros=macros)]
    cmdclass.update({'build_ext': build_ext})
else:
    ext_modules = [Extension('_cbitstring', ['_cbitstring.c'])]


setup(name='bitstring',
      version='3.2.0',
      description='Simple construction, analysis and modification of binary data.',
      author='Scott Griffiths',
      author_email='dr.scottgriffiths@gmail.com',
      url='https://github.com/scott-griffiths/bitstring',
      download_url='https://pypi.python.org/pypi/bitstring/',
      license='The MIT License: http://www.opensource.org/licenses/mit-license.php',
      cmdclass = cmdclass,
      ext_modules = ext_modules,
      py_modules=['bitstring', '_pybitstring'],
      platforms='all',
      classifiers = [
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'Operating System :: OS Independent',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.2',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Topic :: Software Development :: Libraries :: Python Modules',
      ],
      **kwds
      )

