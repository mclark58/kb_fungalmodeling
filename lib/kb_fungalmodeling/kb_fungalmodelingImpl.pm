package kb_fungalmodeling::kb_fungalmodelingImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org
our $VERSION = '0.0.1';
our $GIT_URL = 'https://github.com/janakagithub/kb_fungalmodeling.git';
our $GIT_COMMIT_HASH = '661a64a87ffc7ed21054f1428623f1182b957f70';

=head1 NAME

kb_fungalmodeling

=head1 DESCRIPTION

A KBase module: kb_fungalmodeling
This module  build fungal models based on fungal genomes.

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use Workspace::WorkspaceClient;
use AssemblyUtil::AssemblyUtilClient;
use KBaseReport::KBaseReportClient;
use GenomeProteomeComparison::GenomeProteomeComparisonClient;
use fba_tools::fba_toolsClient;
use Config::IniFiles;
use Bio::SeqIO;
use UUID::Random;
use Data::Dumper;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    my $scratch = $cfg->val('kb_fungalmodeling', 'scratch');
    my $wsInstance = $cfg->val('kb_fungalmodeling','workspace-url');
    my $callbackURL = $ENV{ SDK_CALLBACK_URL };

    $self->{scratch} = $scratch;
    $self->{callbackURL} = $callbackURL;
    $self->{'workspace-url'} = $wsInstance;
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 build_fungal_model

  $output = $obj->build_fungal_model($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_fungalmodeling.fungalmodelbuiltInput
$output is a kb_fungalmodeling.fungalmodelbuiltOutput
fungalmodelbuiltInput is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	genome_ref has a value which is a string
	template_model has a value which is a string
	gapfill_model has a value which is an int
	translation_policy has a value which is a string
	output_model has a value which is a string
fungalmodelbuiltOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_fungalmodeling.fungalmodelbuiltInput
$output is a kb_fungalmodeling.fungalmodelbuiltOutput
fungalmodelbuiltInput is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	genome_ref has a value which is a string
	template_model has a value which is a string
	gapfill_model has a value which is an int
	translation_policy has a value which is a string
	output_model has a value which is a string
fungalmodelbuiltOutput is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description



=back

=cut

sub build_fungal_model
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to build_fungal_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_fungal_model');
    }

    my $ctx = $kb_fungalmodeling::kb_fungalmodelingServer::CallContext;
    my($output);
    #BEGIN build_fungal_model
     # Print statements to stdout/stderr are captured and available as the App log
    print("Starting fungal model building method. Parameters:\n");
    print(Dumper($params) . "\n");


    my $fbaO = new fba_tools::fba_toolsClient( $self->{'callbackURL'},
                                                            ( 'service_version' => 'release',
                                                              'async_version' => 'release',
                                                            )
                                                           );

    my $protC = new GenomeProteomeComparison::GenomeProteomeComparisonClient( $self->{'callbackURL'},
                                                            ( 'service_version' => 'release',
                                                              'async_version' => 'release',
                                                            )
                                                           );

    my $reportHandle = new KBaseReport::KBaseReportClient( $self->{'callbackURL'},
                                                            ( 'service_version' => 'release',
                                                              'async_version' => 'release',
                                                            )
                                                          );

    my $token=$ctx->token;
    my $wshandle= Workspace::WorkspaceClient->new($self->{'workspace-url'},token=>$token);


    #my $ws_name = "secalhoun:narrative_1506371194238";
    #my $ws_name = "janakakbase:narrative_1509376805185";
    my $template_genome_ref = 'CM_Neuro_Cglaba_Ctropi_Aterreus.genome';
    my $template_model_ref = 'CM_Neuro_Cglaba_Ctropi_Aterreus';
    my $ws_name = $params->{workspace};
    my $protCompId = 'proteinComp'.$params->{genome_ref};
    my $tmpGenome;
    my $tmpModel;

    my $templateId = {
      default_temp => [$template_model_ref, $template_genome_ref],
      iJL1454 => ['iJL1454', 'Aspergillus terreus iJL1454'],
      iNX804  => ['iNX804','Candida_glabrata_ASM254'],
      iCT646 => ['iCT646','Candida_tropicali_MYA-3404'],
      iOD907 => ['iOD907','GCF_000002515.2'],
      iJDZ836 => ['iJDZ836','Neurospora_crassa_OR74A'],

    };





    if (defined $params->{template_model}) {

      print "Template selected as $params->{template_model} \n";

      $tmpModel = $templateId->{$params->{template_model}}->[0];
      $tmpGenome = $templateId->{$params->{template_model}}->[1];

      print &Dumper ($templateId);
      print "for the moment setting template to master\n";
      $tmpGenome = $template_genome_ref;
      $tmpModel = $template_model_ref;

    }
    my $tran_policy;
    if (defined $params->{translation_policy}){
      $tran_policy = $params->{translation_policy};

    }

=head
    my $protComp =  $protC->blast_proteomes({
        genome1ws => $params->{workspace},
        genome1id => $params->{genome_ref},
        genome2ws => $params->{workspace},
        genome2id => $tmpGenome,
        output_ws => $ws_name,
        output_id => $protCompId
    });

=cut
    my $fba_modelProp =  $fbaO->propagate_model_to_new_genome({
        fbamodel_id => $tmpModel,
        fbamodel_workspace => $params->{workspace}, # ' janakakbase:narrative_1498154949048', #$ws_name,
        proteincomparison_id => $protCompId,
        proteincomparison_workspace => $params->{workspace},
        fbamodel_output_id =>  $params->{output_model},
        workspace => $params->{workspace},
        keep_nogene_rxn => 1,
        #media_id =>
        #media_workspace =>
        minimum_target_flux => 0.1,
        translation_policy => $tran_policy,
        output_id =>  $params->{output_model}
    });

    my $gpModelFromSource;
    if ($params->{gapfill_model} == 1){

        print "Running gapfill from the source model, may take a while....\n ";
        $gpModelFromSource = $fbaO->gapfill_metabolic_model ({

            fbamodel_id => $params->{output_model},
            fbamodel_output_id => 'Gapfilled_'.$params->{output_model},
            source_fbamodel_id => $tmpModel,
            workspace => $params->{workspace},
            target_reaction => 'bio1',
            feature_ko_list => [],
            reaction_ko_list => [],
            custom_bound_list => [],
            media_supplement_list =>  [],
            minimum_target_flux => 0.1
        });
    }
    else {

        print "Did not run gappfilling, proudced a draft model \n";
    }

       print &Dumper ($gpModelFromSource);

    my $reporter_string = "Fungal model was built based upon proteome comparison $protCompId and produced the model $params->{output_model}\n";

    #die;


    my $uid = UUID::Random::generate;
    my $report_context = {
      message => $reporter_string,
      objects_created => [],
      workspace_name => $params->{workspace},
      warnings => [],
      html_links => [],
      file_links =>[],
      report_object_name => "Report"."modelpropagation"."-".UUID::Random::generate
    };




    my $report_response;

    eval {
      $report_response = $reportHandle->create_extended_report($report_context);
    };
    if ($@){
      print "Exception message: " . $@->{"message"} . "\n";
      print "JSONRPC code: " . $@->{"code"} . "\n";
      print "Method: " . $@->{"method_name"} . "\n";
      print "Client-side exception:\n";
      print $@;
      print "Server-side exception:\n";
      print $@->{"data"};
      die $@;
    }

    print "Report is generated: name and the ref as follows\n";
    print &Dumper ($report_response);
     my $report_out = {
      report_name => $report_response->{name},
      report_ref => $report_response->{ref}
    };
    return $report_out;

    #my $source_genome =$wshandle->get_objects([{ref=>"23505/233/1"}])->[0]

    #END build_fungal_model
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to build_fungal_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_fungal_model');
    }
    return($output);
}




=head2 build_fungal_template

  $output = $obj->build_fungal_template($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_fungalmodeling.fungalReferenceModelBuildInput
$output is a kb_fungalmodeling.fungalReferenceModelBuildOutput
fungalReferenceModelBuildInput is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	reference_genome has a value which is a string
	reference_model has a value which is a string
	genome_ws has a value which is a string
	model_ws has a value which is a string
fungalReferenceModelBuildOutput is a reference to a hash where the following keys are defined:
	master_template_model_ref has a value which is a string
	master_template_genome_ref has a value which is a string

</pre>

=end html

=begin text

$params is a kb_fungalmodeling.fungalReferenceModelBuildInput
$output is a kb_fungalmodeling.fungalReferenceModelBuildOutput
fungalReferenceModelBuildInput is a reference to a hash where the following keys are defined:
	workspace has a value which is a string
	reference_genome has a value which is a string
	reference_model has a value which is a string
	genome_ws has a value which is a string
	model_ws has a value which is a string
fungalReferenceModelBuildOutput is a reference to a hash where the following keys are defined:
	master_template_model_ref has a value which is a string
	master_template_genome_ref has a value which is a string


=end text



=item Description



=back

=cut

sub build_fungal_template
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to build_fungal_template:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_fungal_template');
    }

    my $ctx = $kb_fungalmodeling::kb_fungalmodelingServer::CallContext;
    my($output);
    #BEGIN build_fungal_template

    print &Dumper ($params);
    my $token=$ctx->token;
    my $wshandle = Workspace::WorkspaceClient->new($self->{'workspace-url'},token=>$token);

    my $fbaO = new fba_tools::fba_toolsClient( $self->{'callbackURL'},
                                                            ( 'service_version' => 'release',
                                                              'async_version' => 'release',
                                                            )
                                                           );
    print &Dumper ($wshandle);

    my $ws = $params->{workspace};

    my $start_genome_id  = '25857/2/3'; # 'Neurospora_crassa_OR74A',
    my $start_model_name = '25857/11/2'; # iJDZ836";

    my $first_model;

    eval {
       $first_model = $wshandle->get_objects([{ref=>'25857/4/2'}])->[0];
    };
    if ($@) {
       die "Error loading object from the workspace:\n".$@;
    }


    my $community_model = $fbaO->Omerge_metabolic_models_into_community_model({
       fbamodel_id_list => ["25857/11/2", "25857/12/1"],
       fbamodel_output_id => "community_model_NeurosAndCandida",
       mixed_bag_model => 1

    });

    print &Dumper ($first_model);
    die;


    #END build_fungal_template
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to build_fungal_template:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'build_fungal_template');
    }
    return($output);
}




=head2 status

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my($return);
    #BEGIN_STATUS
    $return = {"state" => "OK", "message" => "", "version" => $VERSION,
               "git_url" => $GIT_URL, "git_commit_hash" => $GIT_COMMIT_HASH};
    #END_STATUS
    return($return);
}

=head1 TYPES



=head2 fungalmodelbuiltInput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a string
genome_ref has a value which is a string
template_model has a value which is a string
gapfill_model has a value which is an int
translation_policy has a value which is a string
output_model has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
genome_ref has a value which is a string
template_model has a value which is a string
gapfill_model has a value which is an int
translation_policy has a value which is a string
output_model has a value which is a string


=end text

=back



=head2 fungalmodelbuiltOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=head2 fungalReferenceModelBuildInput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a string
reference_genome has a value which is a string
reference_model has a value which is a string
genome_ws has a value which is a string
model_ws has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a string
reference_genome has a value which is a string
reference_model has a value which is a string
genome_ws has a value which is a string
model_ws has a value which is a string


=end text

=back



=head2 fungalReferenceModelBuildOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
master_template_model_ref has a value which is a string
master_template_genome_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
master_template_model_ref has a value which is a string
master_template_genome_ref has a value which is a string


=end text

=back



=cut

1;
