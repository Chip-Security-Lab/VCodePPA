//SystemVerilog
module prio_enc_latch_sync #(parameter BITS=6)(
  input clk, latch_en, rst,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] enc_addr
);
  reg [BITS-1:0] latched_data;
  wire [$clog2(BITS)-1:0] priority_addr;
  
  // Latch input data
  always @(posedge clk) begin
    if(rst)
      latched_data <= 0;
    else if(latch_en)
      latched_data <= din;
  end
  
  // Priority encoder logic - combinational block
  // This is extracted to allow optimization and pipelining
  assign priority_addr = find_priority_addr(latched_data);
  
  // Output register update
  always @(posedge clk) begin
    if(rst)
      enc_addr <= 0;
    else
      enc_addr <= priority_addr;
  end
  
  // Priority encoder function with optimized structure
  function [$clog2(BITS)-1:0] find_priority_addr;
    input [BITS-1:0] data;
    reg [$clog2(BITS)-1:0] addr;
    reg found;
    integer j;
    begin
      addr = 0;
      found = 0;
      
      // For smaller bit widths, use binary search approach to reduce logic depth
      if (BITS > 4) begin
        // First check high half of bits
        for(j=BITS/2; j<BITS; j=j+1) begin
          if(data[j] && !found) begin
            addr = j[$clog2(BITS)-1:0];
            found = 1;
          end
        end
        
        // If no high bits set, check lower half
        if (!found) begin
          for(j=0; j<BITS/2; j=j+1) begin
            if(data[j]) begin
              addr = j[$clog2(BITS)-1:0];
            end
          end
        end
      end
      else begin
        // For small bit widths, direct priority encoding is more efficient
        for(j=0; j<BITS; j=j+1) begin
          if(data[j])
            addr = j[$clog2(BITS)-1:0];
        end
      end
      
      find_priority_addr = addr;
    end
  endfunction
  
endmodule