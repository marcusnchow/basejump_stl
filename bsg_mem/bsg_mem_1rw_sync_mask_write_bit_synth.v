// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//
// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1rw_sync_mask_write_bit.
//

module bsg_mem_1rw_sync_mask_write_bit_synth #(parameter width_p=-1
                 , parameter els_p=-1
                 , parameter latch_last_read_p=0
                 , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [width_p-1:0] w_mask_i
    , input w_i
    , output logic [width_p-1:0]  data_o
    );

   wire unused = reset_i;

   logic [addr_width_lp-1:0] addr_r;
   logic [width_p-1:0] mem [els_p-1:0];
   logic read_en;

   assign read_en = v_i & ~w_i;

   always_ff @(posedge clk_i)
     if (read_en)
       addr_r <= addr_i;
     else
       addr_r <= 'X;

   logic [width_p-1:0] data_out;

   assign data_out = mem[addr_r];

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



// The Verilator and non-Verilator models are functionally equivalent. However, Verilator
//   cannot handle an array of non-blocking assignments in a for loop. It would be nice to 
//   see if these two models synthesize the same, because we can then reduce to the Verilator
//   model and avoid double maintenence. One could also add this feature to Verilator...
//   (Identified in Verilator 4.011)
`ifdef VERILATOR
   logic [width_p-1:0] data_n;

   for (genvar i = 0; i < width_p; i++)
     begin : rof1
       assign data_n[i] = w_mask_i[i] ? data_i[i] : mem[addr_i][i];
     end // rof1

   always_ff @(posedge clk_i)
     if (v_i & w_i)
       mem[addr_i] <= data_n;

`else 
   always_ff @(posedge clk_i)
     if (v_i & w_i)
       for (integer i = 0; i < width_p; i=i+1)
         if (w_mask_i[i])
           mem[addr_i][i] <= data_i[i];
`endif

endmodule
