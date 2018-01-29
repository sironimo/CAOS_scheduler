
change_energy <- function(energy_by_core = 3.5, base_factor = 0.4){
  
  base_energy <- energy_by_core * base_factor * 20
  
  
  xml <- paste0("<?xml version='1.0'?>",'
    <!DOCTYPE platform SYSTEM "http://simgrid.gforge.inria.fr/simgrid/simgrid.dtd">
    <platform version="4.1">
      <zone id="network-zone" routing="None">
        
        <cluster id="minihpc" prefix="Xeon" radical="1-22" suffix=".mini" 
        speed="1.25Gf" core="20"
        bw="100Gbps" lat="1.04E-6s">
          
          <prop id="watt_per_state" value="',base_energy,':',base_energy+energy_by_core,':',base_energy+energy_by_core*20,'" />
          <prop id="watt_off" value="',base_energy,'" />
          </cluster>
          
          </zone>
          </platform>')
  
  write(xml, "energy_env/miniHPC_energy.xml")
  
}




change_energy_comb <- function(base_power){
  
  
  xml <- paste0("<?xml version='1.0'?>",'
<!DOCTYPE platform SYSTEM "http://simgrid.gforge.inria.fr/simgrid/simgrid.dtd">
                <platform version="4.1">
                <!--Two over internet combinde clusters
                
                
                Glossar:
                speed: Flops per Core
                watt_per_state idle:one_core:all_cores
                -->
                
                <zone id="world" routing="Full">
                
                <!--Mini HPC from University of Basel-->
                <cluster id="minihpc" prefix="Xeon" radical="1-22" suffix=".mini" 
                speed="1.25Gf" core="20"
                bw="100Gbps" lat="1.04E-6s">
                
          <prop id="watt_per_state" value="',round(base_power),'.0:',57,'.0:',120,'.0" />
          <prop id="watt_off" value="',round(base_power),'" />
                </cluster>
                
                <!--Micro HPC from Univerity of Basel (Anton Gstöhl Bachelor Thesis)-->
                <cluster id="microhpc" prefix="Odroid" radical="1-64" suffix=".micro" 
                speed="0.5Gf" core="4"
                bw="10Gbps" lat="1E-5s">
                
                <prop id="watt_per_state" value="1.0:2.0:5.0" />
                <prop id="watt_off" value="1" />
                </cluster>
                
                
                <link id="backbone" bandwidth="10GBps" latency="1E-5s" sharing_policy="FATPIPE"/>
                
                <zoneRoute src="minihpc" dst="microhpc" 
                gw_src="Xeonminihpc_router.mini"
                gw_dst="Odroidmicrohpc_router.micro">
                <link_ctn id="backbone" />
                </zoneRoute>
                
                
                </zone>
                </platform>')
  
  write(xml, "energy_env/combined_energy.xml")
  
}
