
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