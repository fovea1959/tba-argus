#!/usr/bin/perl

use strict;

use TBA;

use JSON -support_by_pp;

TBA::getAndSave('/api/v2/events/' . TBA::year(), 'eventlist');
