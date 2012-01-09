use strict;
`cat generated | while read f; do rm ../pages/\$f; done`;
`cat /dev/null >generated`;

# handy routines for creating federated wiki pages

sub randomid {
  return sprintf("%08d",rand(10**8)).sprintf("%08d",rand(10**8));
}

sub slug {
  my ($slug) = @_;
  $slug =~ s/\s/-/g;
  $slug =~ s/[^A-Za-z0-9-]//g;
  $slug = lc $slug;
  return $slug;
}

sub page {
  my ($title, @story) = @_;
  my $slug = slug $title;
  my $story = join ',', @story;
  `echo $slug >> generated`;
  open P, ">../pages/$slug";
  print P <<;
        {
          "title": "$title",
          "story": [
            $story
          ]
        }

}

sub paragraph {
  my ($text) = @_;
  $text =~ s/"/\\"/g;
  my $id = randomid();
  return <<;
    {
      "type": "paragraph",
      "id": "$id",
      "text": "$text"
    }

}

sub node {
  return <<;
    {
      "name": "$_[0]",
      "group": $_[1]
    }

}

sub linkk {
  return <<;
    {
      "source": $_[0],
      "target": $_[1],
      "value": $_[2]
    }

}

my (%t, %tt);
my (@index, @pattern) = ((),());

$/ = "\n\n";
sub scan {
  open (H, "ddd.htm") or die $!;
  my $i;
  my $title = 'Unknown Pattern';
  my $part = 'Unknown Part';
  for (<H>) {
    s/\n/ /g;
    s/<span.*<\/p>/* * *<\/p>/ if /PatternSectionBreak/;
    s/<\/?(span|v:|o:|br|a|xml|!).*?>//g;
    map $t{$1}++, /<([a-zA-Z0-9]+)/g;
    s/&nbsp;/ /ig;
    s/  +/ /g;
    my $c = $1 if s/^<p class=(\w+).*?>//;
    $tt{$c ? $c : 'none'}++;
    # $c = $c ? $c : 'none';
    s/<\/?(p).*?>//g;
    s/<b> *<\/b>//g;
    s/$ +//;
    s/ +$//;
    next if /^$/;
    print ++$i, " $c\n\t$_\n\n";
    if ($c =~ /PatternTitle/) {
      page $title, @pattern;
      push @index, paragraph "[[$title]]";
      ($title, @pattern) = ($_, ());
    } elsif ($c =~ /Pattern/) {
      push @pattern, paragraph $_;
    } else {
      push @index, paragraph $_;
    }
  }
  page $title, @pattern;
  page 'Domain Driven Design', @index;
}

scan();
print "\n", map "$t{$_}\t$_\n", sort keys %t;
print "\n", map "$tt{$_}\t$_\n", sort keys %tt;


