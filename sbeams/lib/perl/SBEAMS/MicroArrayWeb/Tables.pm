package SBEAMS::MicroArrayWeb::Tables;

###############################################################################
# Program     : SBEAMS::MicroArrayWeb::Tables
# Author      : Eric Deutsch <edeutsch@systemsbiology.org>
# $Id$
#
# Description : This is part of the SBEAMS::MicroArrayWeb module which provides
#               a level of abstraction to the database tables.
#
###############################################################################


use strict;
use vars qw(@ISA @EXPORT 
    $TB_PROTOCOL
    $TB_PROTOCOL_TYPE
    $TB_HARDWARE
    $TB_HARDWARE_TYPE
    $TB_SOFTWARE
    $TB_SOFTWARE_TYPE
    $TB_SLIDE_TYPE
    $TB_ORGANISM
    $TB_LABELING_METHOD
    $TB_DYE
    $TB_XNA_TYPE
    $TB_ARRAY_REQUEST
    $TB_ARRAY_REQUEST_SLIDE
    $TB_ARRAY_REQUEST_SAMPLE
    $TB_ARRAY_REQUEST_OPTION
    $TB_SLIDE_MODEL
    $TB_SLIDE_LOT
    $TB_SLIDE
    $TB_PRINTING_BATCH
    $TB_ARRAY_LAYOUT
    $TB_ARRAY
    $TB_LABELING
    $TB_HYBRIDIZATION
    $TB_ARRAY_SCAN
    $TB_ARRAY_QUANTITATION

);

require Exporter;
@ISA = qw (Exporter);

@EXPORT = qw (
    $TB_PROTOCOL
    $TB_PROTOCOL_TYPE
    $TB_HARDWARE
    $TB_HARDWARE_TYPE
    $TB_SOFTWARE
    $TB_SOFTWARE_TYPE
    $TB_SLIDE_TYPE
    $TB_ORGANISM
    $TB_LABELING_METHOD
    $TB_DYE
    $TB_XNA_TYPE
    $TB_ARRAY_REQUEST
    $TB_ARRAY_REQUEST_SLIDE
    $TB_ARRAY_REQUEST_SAMPLE
    $TB_ARRAY_REQUEST_OPTION
    $TB_SLIDE_MODEL
    $TB_SLIDE_LOT
    $TB_SLIDE
    $TB_PRINTING_BATCH
    $TB_ARRAY_LAYOUT
    $TB_ARRAY
    $TB_LABELING
    $TB_HYBRIDIZATION
    $TB_ARRAY_SCAN
    $TB_ARRAY_QUANTITATION

);


$TB_PROTOCOL            = 'protocol';
$TB_PROTOCOL_TYPE       = 'protocol_type';
$TB_HARDWARE            = 'hardware';
$TB_HARDWARE_TYPE       = 'hardware_type';
$TB_SOFTWARE            = 'software';
$TB_SOFTWARE_TYPE       = 'software_type';
$TB_SLIDE_TYPE          = 'slide_type';
$TB_ORGANISM            = 'organism';
$TB_LABELING_METHOD     = 'labeling_method';
$TB_DYE                 = 'arrays.dbo.dye';
$TB_XNA_TYPE            = 'xna_type';
$TB_ARRAY_REQUEST       = 'array_request';
$TB_ARRAY_REQUEST_SLIDE = 'array_request_slide';
$TB_ARRAY_REQUEST_SAMPLE= 'array_request_sample';
$TB_ARRAY_REQUEST_OPTION= 'array_request_option';
$TB_SLIDE_MODEL         = 'slide_model';
$TB_SLIDE_LOT           = 'slide_lot';
$TB_SLIDE               = 'slide';
$TB_PRINTING_BATCH      = 'printing_batch';
$TB_ARRAY_LAYOUT        = 'array_layout';
$TB_ARRAY               = 'array';
$TB_LABELING            = 'labeling';
$TB_HYBRIDIZATION       = 'hybridization';
$TB_ARRAY_SCAN          = 'array_scan';
$TB_ARRAY_QUANTITATION  = 'array_quantitation';


