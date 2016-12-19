########################################################################
#   Copyright (c) 2012 Ákos Kovács - Akosix operating system
#              http://akoskovacs.github.com/Akosix
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
########################################################################
#!/usr/bin/perl 

use warnings;
use strict;

my $KERNEL_NAME = $ARGV[0];
my $OUT_FILE = $ARGV[1];

my @nm_out = `nm $KERNEL_NAME`;
my @out_code = ();
my $vtype = ();
my $TIME = localtime(time());
my $out_header = <<EOH;
/****************************************************
                   DO NOT EDIT! 
   Automatically generated by 'scripts/genksyms.pl'
              $TIME
*****************************************************/
#include <ksymbol.h>
#include <string.h>
#include <basic.h>

struct ksymbol sym_table[] = {
EOH

my $out_end = <<EOE;
void *get_ksymbol(const char *name, symbol_type_t flags)
{
    struct ksymbol *sym = sym_table;
    while (sym->ks_name != NULL && sym->ks_address != 0) {
        if ((sym->ks_type & flags) && (strcmp(name, sym->ks_name) == 0))
            return (void *)sym->ks_address;

        sym++;
    }
    return NULL;
}

const char *get_ksymbol_name(unsigned long address)
{
    unsigned int diff, max_diff = 0;
    const char *name = NULL;
    struct ksymbol *sym = sym_table;
    max_diff = (unsigned int)-1; /* Maximal int size */
    do {
        diff = address - sym->ks_address;
        if (diff < max_diff) {
            max_diff = diff;
            name = sym->ks_name;
        }
        sym++;
    } while (sym->ks_name != NULL || sym->ks_address != 0);

    return name;
}
EOE

sub symbol_flag {
    my $sym_type = shift;

    if ($sym_type eq 'T' or $sym_type eq 't') {
        return "SYM_CODE";
    } elsif ($sym_type eq 'B' or $sym_type eq 'b'
                or $sym_type eq 'R') {
        return "SYM_BSS";
    } elsif ($sym_type eq 'd' or $sym_type eq 'D') {
        return "SYM_DATA";
    } elsif ($sym_type eq 'N' or $sym_type eq 'n') {
        return "SYM_DEBUG";
    } else {
        print STDERR "Error: Unknown symbol type '$sym_type'!\n"
    }
}

#==~~~--- main ---~~~==#

if ($#ARGV+1 != 2) {
    die "Usage: [object file] [out code]";
}


push(@out_code, $out_header);
foreach my $line (@nm_out) {
    if ($line =~ /(\w+) (\w) (\w+)/) {
        # Exclude uneeded symbols
        if ($2 eq 'a' or $2 eq 'A' or $2 eq 'r') {
            next;
        }

        $vtype = symbol_flag($2);
        push(@out_code, "\t{ 0x$1, $vtype, \"$3\" },\n");
    }
}

push(@out_code, "\t{ 0x0, 0, NULL }\n};\n\n");
push(@out_code, $out_end);

open(OUT, '>', $OUT_FILE) or die "Cannot create file: $!";
print OUT @out_code;
close(OUT);
