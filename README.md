<h1>Cineca utilities</h1>
<h2>autosbatch_1</h2>
<p>autosbatch_1.sh is a Bash script that automates the preparation and submission of batch jobs for CP2K simulations. It organizes input .inp files, job scripts, and coordinate .xyz files by creating folders for each system, customizing input and job files based on the .xyz filename, and submits the jobs using sbatch.</p>
<h2>autosbatch_2</h2>
<p>autosbatch_2.sh is a Bash automation script designed to prepare and submit CP2K batch jobs for multiple molecules organized in directories. Each directory should contain a coordinate file matching the pattern *-proj-pos-1.xyz. The script generates three separate calculations for each molecule:</p>
<ul>
  <li>Two GEO_OPT optimizations for the anion and cation charged forms</li>
  <li>One WFN_OPT calculation for the neutral form (optionally using a .wfn wavefunction file if present)</li>
</ul>



</p>
