//SystemVerilog
module time_sliced_arbiter(
  input clk, rst_n,
  input [3:0] req,
  output reg [3:0] gnt,
  output reg busy
);
  reg [1:0] time_slice_counter;
  
  // Simplified counter logic - direct increment instead of carry lookahead
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      time_slice_counter <= 2'b00;
      gnt <= 4'b0000;
      busy <= 1'b0;
    end else begin
      // Reset grant signals
      gnt <= 4'b0000;
      
      // Grant based on time slice and request
      case (time_slice_counter)
        2'b00: if (req[0]) gnt[0] <= 1'b1;
        2'b01: if (req[1]) gnt[1] <= 1'b1;
        2'b10: if (req[2]) gnt[2] <= 1'b1;
        2'b11: if (req[3]) gnt[3] <= 1'b1;
      endcase
      
      // Simple increment counter
      time_slice_counter <= time_slice_counter + 1'b1;
      
      // Busy signal is the OR of all grant signals
      busy <= |gnt;
    end
  end
endmodule