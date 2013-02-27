
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
This allows it to do more, and (hopefully) execute more efficiently.
</p>

<h2>Features of the doMPI backend</h2>
<p>
<ul>
  <li>Data that is common to all tasks can be broadcast to the cluster workers,
      or piggy-backed with the first task to the workers.</li>
  <li>It is easy to write scripts that can be executed interactively or in
      batch mode using mpirun.</li>
  <li>A chunkSize option is supported to increase the task granularity for
      better performance.</li>
  <li>If chunkSize is used, and a cluster worker has multiple cores, the mclapply
      function from the 'parallel' package can be used to execute the tasks in parallel,
      thus enabling hybrid parallelism.</li>
  <li>An arbitrarily large number of tasks can be executed, since task arguments
      are not fetched until they are ready to be submitted, and results are
      processed as they are returned.</li>
  <li>Backend-specific options for initializing and finalizing the worker execution
      environments.</li>
  <li>Support for parallel random number generation.</li>
</ul>
</p>

<p> The <strong>project summary page</strong> you can find <a href="http://<?php echo $domain; ?>/projects/<?php echo $group_name; ?>/"><strong>here</strong></a>. </p>

</body>
</html>
