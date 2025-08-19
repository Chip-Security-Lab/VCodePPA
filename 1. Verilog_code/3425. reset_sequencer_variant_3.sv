//SystemVerilog
module reset_sequencer (
  input wire clk,
  input wire global_rst,
  output reg rst_domain1,
  output reg rst_domain2,
  output reg rst_domain3
);
  reg [3:0] seq_counter;
  
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      seq_counter <= 4'd0;
      rst_domain1 <= 1'b1;
      rst_domain2 <= 1'b1;
      rst_domain3 <= 1'b1;
    end else begin
      // Optimized counter increment with saturation logic
      if (seq_counter != 4'd15)
        seq_counter <= seq_counter + 4'd1;
      
      // Optimized reset domain logic using range comparisons
      // Domain 1 reset active for counts 0-2
      rst_domain1 <= (seq_counter < 4'd3);
      
      // Domain 2 reset active for counts 0-6
      rst_domain2 <= (seq_counter < 4'd7);
      
      // Domain 3 reset active for counts 0-10
      rst_domain3 <= (seq_counter < 4'd11);
    end
  end
endmodule