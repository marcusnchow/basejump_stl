// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//
// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1rw_sync.

module bsg_mem_1rw_sync_synth #(parameter width_p=-1
        , parameter els_p=-1
        , parameter latch_last_read_p=0
        , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
   (input   clk_i
	 	, input v_i
		, input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input w_i
    , output logic [width_p-1:0]  data_o
    );

  wire unused = reset_i;

  logic [addr_width_lp-1:0] addr_r;
  logic [width_p-1:0]    mem [els_p-1:0];
  logic read_en;
  logic [width_p-1:0] data_out;

  assign read_en = v_i & ~w_i;
  assign data_out = mem[addr_r];

  always_ff @ (posedge clk_i) 
    if (read_en)
      addr_r <= addr_i;
    else
      addr_r <= 'X;

  if (latch_last_read_p)
    begin: llr
  
      logic read_en_r; 

      always_ff @ (posedge clk_i)
        read_en_r <= read_en;

      bsg_dff_en_bypass #(
        .width_p(width_p)
      ) dff_bypass (
        .clk_i(clk_i)
        ,.en_i(read_en_r)
        ,.data_i(data_out)
        ,.data_o(data_o)
      );

    end
  else
    begin
      assign data_o = data_out;
    end


  always_ff @(posedge clk_i)
    if (v_i & w_i) 
      mem[addr_i] <= data_i;


   // synopsys translate_off
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end

   always_ff @(posedge clk_i)
     if (v_i)
       assert ( (v_i !== 1'b1) || (reset_i === 'X) || (reset_i === 1'b1) || (addr_i < els_p))
         else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_i = %b)\n", addr_i, els_p, reset_i, v_i, clk_i);
   // synopsys translate_on

endmodule
