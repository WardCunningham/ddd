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

my (%t, %tt, %ttt);
my (@index, @pattern) = ((),());

sub mention {
  local $_ = my $ref = $1;
  my %slugs = ("ubiquitous-language"=>1, "model-driven-design"=>1, "hands-on-modelers"=>1, "layered-architecture"=>1, "reference-objects"=>1, "entities"=>1, "value-objects"=>1, "services"=>1, "packages"=>1, "modules"=>1, "aggregates"=>1, "factories"=>1, "repositories"=>1, "intention-revealing-interfaces"=>1, "side-effect-free-functions"=>1, "assertions"=>1, "conceptual-contours"=>1, "standalone-classes"=>1, "closure-of-operations"=>1, "bounded-context"=>1, "continuous-integration"=>1, "context-map"=>1, "shared-kernel"=>1, "customersupplier-development-teams"=>1, "conformist"=>1, "anticorruption-layer"=>1, "separate-ways"=>1, "open-host-service"=>1, "published-language"=>1, "core-domain"=>1, "generic-subdomains"=>1, "domain-vision-statement"=>1, "highlighted-core"=>1, "cohesive-mechanisms"=>1, "segregated-core"=>1, "abstract-core"=>1, "evolving-order"=>1, "system-metaphor"=>1, "responsibility-layers"=>1, "knowledge-level"=>1, "pluggable-component-framework"=>1, "domain-driven-design"=>1);
  s/^ +//;
  s/[., ]+$//;
  s/^Core$/Core domain/;
  s/^aggregate$/aggregates/;
  s/^bounded contexts$/bounded context/;
  s/^closure$/closure of operations/;
  s/^cohesive mechanism$/cohesive mechanisms/;
  s/^conformity$/conformist/;
  s/^context$/context map/;
  s/^core$/core domain/;
  s/^domain$/core domain/;
  s/^entity$/entities/;
  s/^intention-revealing interface$/intention-revealing interfaces/;
  s/^layers?$/layered-architecture/;
  s/^model-driven$/model-driven design/;
  s/^module$/modules/;
  s/^service$/services/;
  s/^value( object)?$/value objects/;
  $ttt{$_}++ unless $slugs{slug($_)};
  return "[[$_]]" if $slugs{slug($_)};
  $ref;
}

$/ = "\n\n";
sub scan {
  open (H, "ddd.htm") or die $!;
  my $i;
  my $title = 'Unknown Pattern';
  my $part = 'Unknown Part';
  for (<H>) {
    s/\n/ /g;
    s/<span class=PatternMention>(.*?)<\/span>/&mention()/geo;
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
print "\n", map "$ttt{$_}\t$_\n", sort keys %ttt;


