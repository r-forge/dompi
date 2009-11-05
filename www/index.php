
<!-- This is the project specific website template -->
<!-- It can be changed as liked or replaced by other content -->

<?php

$domain=ereg_replace('[^\.]*\.(.*)$','\1',$_SERVER['HTTP_HOST']);
$group_name=ereg_replace('([^\.]*)\..*$','\1',$_SERVER['HTTP_HOST']);
$themeroot='http://r-forge.r-project.org/themes/rforge/';

echo '<?xml version="1.0" encoding="UTF-8"?>';
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en   ">

  <head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title><?php echo $group_name; ?></title>
	<link href="<?php echo $themeroot; ?>styles/estilo1.css" rel="stylesheet" type="text/css" />
  </head>

<body>

<!-- R-Forge Logo -->
<table border="0" width="100%" cellspacing="0" cellpadding="0">
<tr><td>
<a href="/"><img src="<?php echo $themeroot; ?>/images/logo.png" border="0" alt="R-Forge Logo" /> </a> </td> </tr>
</table>


<!-- get project title  -->
<!-- own website starts here, the following may be changed as you like -->

<h1>Welcome to the doMPI project</h1>
<p>
The 'doMPI' package provides a parallel backend for the 'foreach' package.
It is similar to the 'doSNOW' package, but uses 'Rmpi' directly.
This allows it to do more, and execute more efficiently.
</p>

<h2>Features of the doMPI backend</h2>
<p>
<ul>
  <li>Tasks arguments are fetched when they are submitted to a cluster worker.</li>
  <li>Results are processed by the master as they are returned by the cluster workers.</li>
  <li>A chunkSize option is supported to increase task granularity for
      better performance.</li>
  <li>If chunkSize is used, and a cluster worker has multiple cores, the mclapply
      function from the 'multicore' package is used to execute the tasks in parallel.
      This enables hybrid parallelism.</li>
  <li>Data that is common to all tasks is broadcast to the cluster workers.</li>
  <li>Backend-specific options for initializing and finalizing the worker execution
      environments.</li>
</ul>
</p>

<p> The <strong>project summary page</strong> you can find <a href="http://<?php echo $domain; ?>/projects/<?php echo $group_name; ?>/"><strong>here</strong></a>. </p>

</body>
</html>
