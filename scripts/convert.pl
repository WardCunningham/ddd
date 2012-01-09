use strict;
use MIME::Base64;

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

sub image {
  my ($tag) = @_;
  return paragraph $tag unless $tag =~ /src="(.*?)\.(jpg|gif|png)"/;
  my ($file, $type) = ("$1.$2", $2);
  my $id = randomid();
  my $bin = encode_base64 `cat $file`;
  $bin =~ s/\s//g;
  return <<;
    {
      "type": "image",
      "id": "$id",
      "url": "data:image/$type;base64,$bin",
      "caption": "$file"
    }

}

# scan the word generated html picking out content based on well chosen style names

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
      if (@pattern) {
        page $1, (paragraph "See [[$title]]") if $title =~ s/ \(aka (.*?)\)//;
        page $title, @pattern;
        push @index, paragraph "[[$title]]";
      }
      ($title, @pattern) = ($_, ());
    } elsif ($c =~ /PatternIllustration/) {
      push @pattern, image $_
    } elsif ($c =~ /Illustration/) {
      push @index, image $_
    } elsif (/^<img/) {
      push @index, image $_
    } elsif ($c =~ /Pattern/) {
      push @pattern, paragraph $_;
    } else {
      push @index, paragraph $_;
    }
  }
  page $title, @pattern;
  page 'Domain Driven Design', @index;
}

# perform the conversion, report stats that help make sure we're not missing things

scan();
print "\n", map "$t{$_}\t$_\n", sort keys %t;
print "\n", map "$tt{$_}\t$_\n", sort keys %tt;


