{package SBEAMS::PeptideAtlas::Glyco_peptide_load;
		



##############################################################
use strict;
use vars qw($sbeams $self);		#HACK within the read_dir method had to set self to global: read below for more info

use File::Basename;
use File::Find;
use File::stat;
use Data::Dumper;
use Carp;
use FindBin;
use POSIX qw(strftime);

		
use SBEAMS::Connection::Tables;
use SBEAMS::PeptideAtlas::Tables;

#use base qw(SBEAMS::PeptideAtlas::Affy);		#declare superclass




#######################################################
# Constructor
#######################################################
sub new {
	my $class = shift;
	
	my %args = @_;
	my $sbeams = $args{sbeams};
	my $verbose = $args{verbose};
	my $debug  = $args{debug};
	my $test_only = $args{test_only};
	my $file = $args{file};
	
	die "Must give file name '$file' is not good\n" unless $file;
	my $self = {_file => $file};
	
	bless $self, $class;
	
	$self->setSBEAMS($sbeams);
	$self->verbose($verbose);
	$self->debug($debug);
	$self->testonly($test_only);
	$self->check_version();
	
	return $self;
	
	
}
###############################################################################
# Receive the main SBEAMS object
###############################################################################
sub setSBEAMS {
    my $self = shift;
    $sbeams = shift;
    return($sbeams);
}


###############################################################################
# Provide the main SBEAMS object
###############################################################################
sub getSBEAMS {
    my $self = shift;
    return($sbeams);
}

###############################################################################
# Get/Set the VERBOSE status
#
#
###############################################################################
sub verbose {
	my $self = shift;
	
		
	if (@_){
		#it's a setter
		$self->{_VERBOSE} = $_[0];
	}else{
		#it's a getter
		$self->{_VERBOSE};
	}
}
###############################################################################
# Get/Set the DEBUG status
#
#
###############################################################################
sub debug {
	my $self = shift;
	
		
	if (@_){
		#it's a setter
		$self->{_DEBUG} = $_[0];
	}else{
		#it's a getter
		$self->{_DEBUG};
	}
}
###############################################################################
# Get/Set the TESTONLY status
#
#
###############################################################################
sub testonly {
	my $self = shift;
	if (@_){
		#it's a setter
		$self->{_TESTONLY} = $_[0];
	}else{
		#it's a getter
		$self->{_TESTONLY};
	}
}

##############################################################################
# Get file to parse
#
#
###############################################################################
sub getfile {
	my $method = 'getfile';
	my $self = shift;
	
	return	$self->{_file};
}

###############################################################################
# parse data file
#
###############################################################################
sub parse_data_file {
	my $self = shift;
	
	my @all_data = ();
  
    open DATA, $self->getfile() or
                die "CANNOT OPEN FILE. $self->getfile() . '$!' \n";

    my %headers = ();
	my $count = 0;
	my $insert_count = 1;
        while(<DATA>){
            chomp;
			my @line_parts = split /\t/, $_;       #split on the quotes and comma.  Commas do exists in some of the data fields
			
			if ($count == 0){
				%headers = $self->column_headers(\@line_parts);
				$count ++;
				next;
			}
			my %record_h = ();
           # next unless  $line_parts[0] eq 'IPI00015102'; #DEBUG ONLY
			my $ipi_id = $line_parts[0];
			
			$self->add_ipi_record(\@line_parts) unless $self->check_ipi($ipi_id);
		
			my $glyco_pk = $self->add_glyco_site(\@line_parts);
			
			$self->add_predicted_peptide(glyco_pk => $glyco_pk,
										 line_parts =>\@line_parts);
			
			$self->add_identifed_peptides(glyco_pk => $glyco_pk,
										 line_parts =>\@line_parts);
		
			
			if ($self->verbose() > 1 ) {
				for (my $i = 0; $i <= $#line_parts; $i ++){
		
					my $name = $headers{$i};
		             print  "$i $name => $line_parts[$i]\n";
					$record_h{$name} = $line_parts[$i];
				}
			}		
		
			$count ++;
			#last if $count == 10;	#DEBUG ONLY

			#print a little message to indicate script is running
			if (100  == $insert_count){
				print "Current Line '$count'\n";
				$insert_count = 1;
			}else{
				$insert_count++;
			}
        }

}


=head1 example columns
0 IPI => IPI00015102
1 Protein Name => CD166 antigen precursor
2 Protein Sequences => MESKGASSCRLLFCLLISATVFRPGLGWYTVNSAYGDTIIIPCRLDVPQNLMFGKWKYEKPDGSPVFIAFRSSTKKSVQYDDVPEYKDRLNLSENYTLSISNARISDEKRFVCMLVTEDNVFEAPTIVKVFKQPSKPEIVSKALFLETEQLKKLGDCISEDSYPDGNITWYRNGKVLHPLEGAVVIIFKKEMDPVTQLYTMTSTLEYKTTKADIQMPFTCSVTYYGPSGQKTIHSEQAVFDIYYPTEQVTIQVLPPKNAIKEGDNITLKCLGNGNPPPEEFLFYLPGQPEGIRSSNTYTLMDVRRNATGDYKCSLIDKKSMIASTAITVHYLDLSLNPSGEVTRQIGDALPVSCTISASRNATVVWMKDNIRLRSSPSFSSLHYQDAGNYVCETALQEVEGLKKRESLTLIVEGKPQIKMTKKTDPSGLSKTIICHVEGFPKPAIQWTITGSGSVINQTEESPYINGRYYSKIIISPEENVTLTCTAENQLERTVNSLNVSAISIPEHDEADEISDENREKVNDQAKLIVGIVVGLLLAALVAGVVYWLYMKKSKTASKHVNKDLGNMEENKKLEENNHKTEA
3 Protein Symbol => ALCAM
4 Swiss-Prot => Q13740
5 Summary =>
6 Synonyms => CD166 antigen precursor (Activated leukocyte-cell adhesion molecule) (ALCAM).
7 Protein Location => S
8 signalP =>  28 Y 0.988 Y
9 TM => 1
10 TM location => o528-550i
11 Num Nxts Sites => 10
12 Nxts Sites => 91,95,167,265,306,337,361,457,480,499
13 Peptide IPI => IPI00015102
14 NXT/S Location => 265
15 NXT/S Score => 0.6163598427746358
16 Predicted Tryptic NXT/S Peptide Sequenc.e => K.EGDN#ITLK.C
17 Predicted Peptide Mass => 888.444684
18 Database Hits => 1
19 Database Hit IPIs => IPI00015102
20 Min Similarity Score => 1.0
21 Detection Probability =>
22 Identified Sequences => K.NAIKEGDN#ITLK.C
23 Tryptic Ends => 2
24 Peptide ProPhet => 0.8636
25 Identified Peptide Mass => 1315.7

=cut
##############################################################################
#Add the identifed_peptide for a row
###############################################################################
sub add_identifed_peptides{
	my $method = 'add_identifed_peptides';
	my $self = shift;
	my %args = @_;
	my $info_aref = $args{line_parts};
	my $glyco_pk = $args{glyco_pk};
	
	
	
	return unless ($info_aref->[22]); #make sure we have an identifed peptide otherwise do nothing
	
	my $ipi_acc = $info_aref->[0];
	my $clean_seq = $self->clean_seq($info_aref->[22]); 
	my ($start, $stop) = $self->map_peptide_to_protein(peptide=> $clean_seq,
													   protein_seq => $info_aref->[2]);
	
	
	my %rowdata_h = ( 	
					
					ipi_data_id => $self->get_ipi_data_id($ipi_acc),
					identified_peptide_sequence => $info_aref->[22],
					tryptic_end					=> $info_aref->[23],
					peptide_prophet_score 		=> $info_aref->[24],
					peptide_mass 				=> $info_aref->[25],
					identified_start 	=> $start,
					identified_stop 	=> $stop, 
					glyco_site_id  		=> $glyco_pk,
					
					
			);
	
	my $rowdata_ref = \%rowdata_h;
	my $identified_peptide_id = $sbeams->updateOrInsertRow(				
							table_name=>$TBAT_IDENTIFIED_PEPTIDE,
				   			rowdata_ref=>$rowdata_ref,
				   			return_PK=>1,
				   			verbose=>$self->verbose(),
				   			testonly=>$self->testonly(),
				   			insert=>1,
				   			PK=>'identified_peptide_id',
				   		   );
				   		   
	if ($self->verbose()>0){
		print (__PACKAGE__."::$method Added IDENTIFIED PEPTIDE pk '$identified_peptide_id'\n");
	
	}
	
	$self->peptide_to_tissue($identified_peptide_id, $info_aref);
	
	return $identified_peptide_id;
}


##############################################################################
#Add peptide_to_tissue information
###############################################################################
sub peptide_to_tissue {
	my $method = 'peptide_to_tissue';
	my $self = shift;
	my $identified_peptide_id = shift;
	my $info_aref = shift;
	
	my $tissue_name = $info_aref->[26]?$info_aref->[26]:'serum'; #data incomplete for version 4 default to serum
	
	my $tissue_id = $self->find_tissue_id($tissue_name);
	
	my %rowdata_h = ( 	
					identified_peptide_id =>$identified_peptide_id,
					tissue_id => $tissue_id
			);

	my $rowdata_ref = \%rowdata_h;
	

	my $peptide_to_tissue_id = $sbeams->updateOrInsertRow(				
							table_name=>$TBAT_PEPTIDE_TO_TISSUE,
				   			rowdata_ref=>$rowdata_ref,
				   			return_PK=>1,
				   			verbose=>$self->verbose(),
				   			testonly=>$self->testonly(),
				   			insert=>1,
				   			PK=>'peptide_to_tissue_id',
				   		   );
				   		   
	if ($self->verbose()>0){
		print (__PACKAGE__."::$method Added PEPTIDE TO TISSUE INFO '$peptide_to_tissue_id'  for tiusse '$tissue_name'$\n");
	
	}
	
	return $peptide_to_tissue_id;
	
}


##############################################################################
#Add the predicted peptide for a row
###############################################################################
sub add_predicted_peptide {
	my $method = 'add_predicted_peptide';
	my $self = shift;
	
	my %args = @_;
	my $info_aref = $args{line_parts};
	my $glyco_pk = $args{glyco_pk};
	
	
	my $ipi_acc = $info_aref->[0];
	
	#my $fixed_predicted_seq = $self->fix_predicted_peptide_seq($info_aref->[16]);
	my $clean_seq = $self->clean_seq($info_aref->[16]); 
	my ($start, $stop) = $self->map_peptide_to_protein(peptide=> $clean_seq,
													   protein_seq => $info_aref->[2]);
	
	#TODO WARNING DETECTION PROBABLITY IS FAKE>  DATA IS NOT COMPLETE
	my %rowdata_h = ( 	
					ipi_data_id 				=> $self->get_ipi_data_id($ipi_acc),
					predicted_peptide_sequence => $info_aref->[16],
					
					predicted_peptide_mass 		=> $info_aref->[17],
					detection_probability 		=> 0, #$info_aref->[21],
					number_proteins_match_peptide => $info_aref->[18],
					matching_protein_ids 		=> $info_aref->[19],
					protein_similarity_score	=> $info_aref->[20],
					predicted_start 			=> $start,
					predicted_stop 				=> $stop,
					glyco_site_id  				=> $glyco_pk,
					
			);
#TODO REMOVE SIZE LIMIT OF DATA	
	#my %rowdata_h = $self->truncate_data(record_href => \%rowdata_h); #some of the data will need to truncated to make it easy to put all data in varchar 255 or less
	my $rowdata_ref = \%rowdata_h;
	

	my $predicted_peptide_id = $sbeams->updateOrInsertRow(				
							table_name=>$TBAT_PREDICTED_PEPTIDE,
				   			rowdata_ref=>$rowdata_ref,
				   			return_PK=>1,
				   			verbose=>$self->verbose(),
				   			testonly=>$self->testonly(),
				   			insert=>1,
				   			PK=>'predicted_peptide_id',
				   		   );
				   		   
	if ($self->verbose()>0){
		print (__PACKAGE__."::$method Added PREDICTED PEPTIDE pk '$predicted_peptide_id'\n");
	
	}
	
	return $predicted_peptide_id;
}


###############################################################################
# fix_predicted_peptide_seq 
# predicted peptide sequences did not have a trailing . denoting the peptide/protein
#cleavage site.  Need to add it back in
###############################################################################
sub fix_predicted_peptide_seq {
	my $method = 'fix_predicted_peptide_seq';
	my $self = shift;
	my $pep_seq = shift;
	
	if ($pep_seq =~ s/(.)$/.$1/){
		if($self->verbose){
			print (__PACKAGE__."::$method ADDED TRAILING CUT SITE '$pep_seq'\n");
	}
		return $pep_seq;
	}else{
		confess(__PACKAGE__."$method COULD NOT REPLACE THE TRAILING CUT SITE in '$pep_seq'\n"); 
	}
	
}
###############################################################################
# clean_seq remove the start and finish protein aa.  Remove any non aa from
# from a peptide sequence
###############################################################################
sub clean_seq {
	my $method = 'clean_seq';
	my $self = shift;
	my $pep_seq = shift;
	unless($pep_seq){
		confess(__PACKAGE__."$method MUST PROVIDE A PEPTIDE SEQUENCE YOU GAVE '$pep_seq'\n");
	}	
	 $pep_seq =~ s/^.//; #remove first aa
		unless($pep_seq){
		confess(__PACKAGE__."$method PEP SEQ IS GONE'$pep_seq'\n");
	}	
	
	 $pep_seq =~ s/.$//; #remove last aa
	
	 $pep_seq =~ s/\W//g;	#remove any '*' '.' '#' signs
	
	unless($pep_seq){
		confess(__PACKAGE__."$method PEP SEQ IS GONE'$pep_seq'\n");
	}	
	
	if($self->verbose){
			print (__PACKAGE__."::$method CLEAN SEQ '$pep_seq'\n");
	}
	 if ($pep_seq =~ /\W/){
		confess(__PACKAGE__."$method PEPTIDE SEQUENCE  IS NOT CLEAN '$pep_seq'\n"); 
	}
	return $pep_seq;
}
	
###############################################################################
#map_peptide_to_protein
###############################################################################
sub map_peptide_to_protein {
	my $method = 'map_peptide_to_protein';
	my $self = shift;
	my %args = @_;
	my $pep_seq = $args{peptide};
	my $protein_seq = $args{protein_seq};
	
	if ( $protein_seq =~ /$pep_seq/ ) {
		#add one for the starting position since we want the start of the peptide location
		
		my $start_pos = length($`) +1;    
		my $stop_pos = length($pep_seq) + $start_pos - 1 ;    #subtract 1 since we want the ture end 
		if($self->verbose){
			print (__PACKAGE__."::$method $pep_seq START '$start_pos' STOP '$stop_pos'\n");
		}
		if ($start_pos >= $stop_pos){
			confess(__PACKAGE__. "::$method STOP LESS THAN START START '$start_pos' STOP '$stop_pos'\n");
		}
		return ($start_pos, $stop_pos);	
	}else{
		confess(__PACKAGE__. "::$method PEPTIDE '$pep_seq' DOES NOT MATCH '$protein_seq'\n");
	
	}
	
}



###############################################################################
#Add the glycosite for this row
###############################################################################
sub add_glyco_site {
	my $method = 'add_glyco_site';
	my $self = shift;
	my $info_aref = shift;
	
	my $ipi_acc = $info_aref->[0];
	
	
	my %rowdata_h = ( 	
				
				protein_glyco_site_position => $info_aref->[14],
				glyco_score =>$info_aref->[15],
				ipi_data_id => $self->get_ipi_data_id($ipi_acc),
			  );
	
	my $rowdata_ref = \%rowdata_h;
	

	my $glyco_site_id = $sbeams->updateOrInsertRow(				
							table_name=>$TBAT_GLYCO_SITE,
				   			rowdata_ref=>$rowdata_ref,
				   			return_PK=>1,
				   			verbose=>$self->verbose(),
				   			testonly=>$self->testonly(),
				   			insert=>1,
				   			PK=>'glyco_site_id',
				   		   );
				   		   
	if ($self->verbose()>0){
		print (__PACKAGE__."::$method Added GLYCOSITE pk '$glyco_site_id'\n");
	
	}
	
	return $glyco_site_id;
}

###############################################################################
#Add the main info for an ipi record
###############################################################################
sub add_ipi_record {
	my $self = shift;
	my $info_aref = shift;
	die "Did not bass aref of data\n" unless (ref($info_aref));
	
	my $cellular_location_id = $self->find_cellular_location_id($info_aref->[7]);
	
	my $ipi_id = $info_aref->[0];
	
	my $ipi_version_id = $self->ipi_version_id();
	
												
	my %rowdata_h = ( 	
				
				ipi_version_id => $ipi_version_id,
				ipi_accession_number =>$ipi_id,
				protein_name =>$info_aref->[1],
				protein_symbol =>$info_aref->[3],
				swiss_prot_acc =>$info_aref->[4],
				cellular_location_id =>$cellular_location_id,
				transmembrane_info =>$info_aref->[10],
				signal_sequence_info =>$info_aref->[8],
				synonyms => $info_aref->[6],
			  );

	my %rowdata_h = $self->truncate_data(record_href => \%rowdata_h); #some of the data will need to truncated to make it easy to put all data in varchar 255 or less
	
	##Add in the big columns that should not be truncated
	
	$rowdata_h{protein_sequence} = $info_aref->[2];
	$rowdata_h{protein_summary}  = $info_aref->[5];
	
	
	my $rowdata_ref = \%rowdata_h;
	

	my $ipi_data_id = $sbeams->updateOrInsertRow(				
							table_name=>$TBAT_IPI_DATA,
				   			rowdata_ref=>$rowdata_ref,
				   			return_PK=>1,
				   			verbose=>$self->verbose(),
				   			testonly=>$self->testonly(),
				   			insert=>1,
				   			PK=>'ipi_data_id',
				   		   );
	
	$self->{All_records}{$ipi_id} = {ipi_data_id => $ipi_data_id};

	
	

	return 1;
}
###############################################################################
#get ipi_data_id 
#given a ipi_accession_number 
#return id if present
#die otherwise
###############################################################################
sub get_ipi_data_id{
	my $method = 'get_ipi_data-id';
	my $self = shift;
	my $ipi_acc = shift;
	
	if (exists $self->{All_records}{$ipi_acc}){
		return $self->{All_records}{$ipi_acc}{ipi_data_id};
		
	}else{
		confess(__PACKAGE__. "::$method COULD NOT FIND ID '$ipi_acc'\n");
		
	}
	
}
###############################################################################
#Given the name of a tissue look return a tissue id
###############################################################################

sub find_tissue_id {
	my $self = shift;
	my $tissue_name = shift;
	my $code = '';
	if ($self->tissue_code_id($tissue_name)){
		#print "I SEE THE CODE **\n";
		return 	$self->tissue_code_id($tissue_name);	
	}else{
		return $self->find_tissue_code($tissue_name);
	}
}

###############################################################################
#Get/Set the tissue code_id 
###############################################################################
sub tissue_code_id {
	my $self = shift;
	
	if (@_){
		#it's a setter
		$self->{_TISSUE_NAMES}{$_[0]} = $_[1];
	}else{
		#it's a getter
		$self->{_CELLULAR_NAMES}{$_[0]};
	}

}

##############################################################################
#Query the database for the tissue code
###############################################################################
sub find_tissue_code {
	my $method = 'find_tissue_code';
	my $self = shift;
	my $tissue_name = shift;
	
	
	my $sql = qq~ 	SELECT tissue_id
					FROM $TBAT_TISSUE
					WHERE tissue_name = '$tissue_name'
		      ~;
	
	
	 my ($id) = $sbeams->selectOneColumn($sql);
	if ($self->verbose){
		print __PACKAGE__. "::$method FOUND TISSUE ID '$id' FOR TISSUE '$tissue_name'\n";
		
	}
	unless ($id) {
		confess(__PACKAGE__ ."::$method CANNOT FIND ID FOR FOR TISSUE '$tissue_name'\n");
	}
	
	$self->tissue_code_id($tissue_name, $id);
	return $id;
}


###############################################################################
#If the ipi_protein has been seen return 0 otherwise retrun 1
###############################################################################
sub find_cellular_location_id{
	my $self = shift;
	my $cellular_code = shift;
	
	
	my $code = '';
	if ($self->cellular_code_id($cellular_code)){
		#print "I SEE THE CODE **\n";
		return 	$self->cellular_code_id($cellular_code);
		
	}else{
	
		return $self->find_cellular_code($cellular_code);
	}

}

###############################################################################
#Convert the cellular code to and a name and find it in the database
###############################################################################
sub find_cellular_code {
	my $method = 'find_cellular_code';
	my $self = shift;
	my $code = shift;
	
	my $full_name = '';
	if ($code eq 'S'){
		$full_name = 'Secreted';
	}elsif($code eq 'TM'){
		$full_name = 'Trans Membrane';
	}elsif($code eq 'A'){
		$full_name = 'Anchor';
	}elsif($code == 0){
		$full_name = 'Cytoplasmic';
	}else{
		print "ERROR:Cannot find full name for CELLULAR CODE '$code'\n";
	}
	my $sql = qq~ 	SELECT cellular_location_id
					FROM $TBAT_CELLULAR_LOCATION
					WHERE cellular_location_name = '$full_name'
		      ~;
	
	
	 my ($id) = $sbeams->selectOneColumn($sql);
	if ($self->verbose){
		print __PACKAGE__. "::$method FOUND CELLULAR LOCATION ID '$id' FOR CODE '$code' FULL NAME '$full_name'\n";
		
	}
	unless ($id) {
		confess(__PACKAGE__ ."::$method CANNOT FIND ID FOR CODE '$code' FULL NAME '$full_name'\n");
	}
	
	$self->cellular_code_id($code, $id);
	return $id;
}
###############################################################################
#Get/Set the cellular code_id cellular_code
###############################################################################
sub cellular_code_id {
	my $self = shift;
	
	if (@_){
		#it's a setter
		$self->{_CELLULAR_CODES}{$_[0]} = $_[1];
	}else{
		#it's a getter
		$self->{_CELLULAR_CODES}{$_[0]};
	}

}

###############################################################################
#If the ipi_protein has been seen return 0 otherwise retrun 1
###############################################################################
sub check_ipi {
	my $method = 'check_ipi';
	my $self = shift;
	my $ipi_id = shift;
	
	confess(__PACKAGE__ . "::$method Need to provide IPI id '$ipi_id' is not good  \n")unless $ipi_id =~ /^IPI/;
	if (exists $self->{All_records}{$ipi_id} ){
		return 1;
	}else{
		return 0;
	}


}

###############################################################################
#check_version
###############################################################################
sub check_version {
	my $method = 'check_version';
	my $self = shift;
	
	my $file = $self->getfile();
	
	my $st = stat($file);
	
	#DB time '2005-05-06 14:24:37.63' 
	my $now_string = strftime "%F %H:%M:%S.00", localtime($st->mtime);
	              
		
	my $sql = qq~ SELECT ipi_version_id
					FROM $TBAT_IPI_VERSION
					WHERE ipi_version_date = '$now_string'
				~;
	
	if ($self->debug >0){
		print __PACKAGE__ ."::$method SQL '$sql'\n";
	}
	
	 my ($id) = $sbeams->selectOneColumn($sql);	
	 
	 if ($id){
	 	$self->ipi_version_id($id);
	 	if ($self->verbose){
	 		print __PACKAGE__. "::$method FOUND IPI VERSION ID IN THE DB '$id'\n";
	 	}
	 }else{
	 	my $id = $self->add_new_ipi_version();
	 	print __PACKAGE__ ."::$method MADE NEW IPI VESION ID '$id'\n";
	 	
	 }
	return 1;
}


###############################################################################
#add_new_ipi_version/set ipi_version_id
###############################################################################	
sub add_new_ipi_version{

	my $self = shift;
	my $file = $self->getfile();
	my $file_name = basename($file);
	
	my $st = stat($file);
	my $mod_time_string = strftime "%F %H:%M:%S.00", localtime($st->mtime);
	
	
	my %rowdata_h = ( 	
				ipi_version_name => $file_name,
				ipi_version_date => $mod_time_string,
				
			  );
	
	my $ipi_version_id = $sbeams->updateOrInsertRow(				
							table_name=>$TBAT_IPI_VERSION,
				   			rowdata_ref=> \%rowdata_h,
				   			return_PK=>1,
				   			verbose=>$self->verbose(),
				   			testonly=>$self->testonly(),
				   			insert=>1,
				   			PK=>'ipi_version_id',
				   		   	add_audit_parameters => 1,
				   		   );
				   		   
				   		   
	return $self->ipi_version_id($ipi_version_id);

}
###############################################################################
#get/set ipi_version_id
#return the ipi_version_id in either case
###############################################################################
sub ipi_version_id {
	my $self = shift;
	
	if (@_){
		#it's a setter
		$self->{_IPI_VERSION_ID} = $_[0];
		return $_[0];
	}else{
		#it's a getter
		return $self->{_IPI_VERSION_ID};
	}

}	
	


###############################################################################
#Column headers
###############################################################################
sub column_headers {
	my $self = shift;
	my $line_aref = shift;
	
	my %headers = ();
	my $count = 0;
	foreach my $name (@{$line_aref}){
		$headers{$count} = $name;
		$count ++;
	}
	
	return %headers;
}



###############################################################################
#truncate_data
#used to truncate any long fields.  Will truncate everything in a hash or a single value to 254 char.  Also will
#write out to the error log if any extra fields are truncated
###############################################################################
sub truncate_data {
    	my $method = 'truncate_data';
    	
	my $self = shift;
	
	my %args = @_;
	
	my $record_href = $args{record_href};
	my $data_aref	= $args{data_aref};
	
	confess(__PACKAGE__ . "::$method Need to provide key value pair 'record_href' OR  'data_aref'\n") unless ( ref($record_href) eq 'HASH' || ref($data_aref) eq 'ARRAY' );
	
	my %record_h = ();
	my @data = ();
	
	if ($record_href){
		%record_h = %{$record_href};
	
		foreach my $key ( keys %record_h){
		
			
			if (length $record_h{$key} > 255){
				my $big_val = $record_h{$key};
		
				my $truncated_val = substr($record_h{$key}, 0, 254);
			
				$self->anno_error(error => "Warning HASH Value truncated for key '$key'\n,ORIGINAL VAL SIZE:". length($big_val). "'$big_val'\nNEW VAL SIZE:" . length($truncated_val) . "'$truncated_val'");
				#print "VAL '$record_h{$key}'\n"
				$record_h{$key} = $truncated_val;
			}
		}
		return %record_h;
	
	}elsif($data_aref){
		@data = @$data_aref;
		
		for(my $i=0; $i<=$#data; $i++){
			if (length $data[$i] > 255){
				my $big_val = $data[$i];
		
				my $truncated_val = substr($data[$i], 0, 254);
			
				$self->anno_error(error => "Warning DATA Val truncated\n,ORIGINAL VAL SIZE:". length($big_val). "'$big_val'\nNEW VAL SIZE:" . length($truncated_val) . "'$truncated_val'");
				#print "VAL '$record_h{$key}'\n"
				$data[$i] = $truncated_val;
			}
		}
		return @data;
	}else{
		die "Unknown DATA TYPE FOR $method\n";
	}

	

}


##############################################################################
# anno_error
###############################################################################
sub  anno_error {
	my $method = 'anno_error';
	my $self = shift;
	
	my %args = @_;
	
	if (exists $args{error} ){
		if ($self->verbose() > 0){
			print "$args{error}\n";
		}
		return $self-> {ERROR} .= "\n$args{error}";	#might be more then one error so append on new errors
		
	}else{
		$self->{ERROR};
	
	}


}



}#closing bracket for the package

1;
