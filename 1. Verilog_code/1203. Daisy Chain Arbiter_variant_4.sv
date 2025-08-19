//SystemVerilog
module daisy_chain_arbiter(
  input clk, reset,
  input [3:0] request,
  output reg [3:0] grant
);
  // Registered request signals
  reg [3:0] request_reg;
  
  // Register the input requests
  always @(posedge clk) begin
    if (reset) begin
      request_reg <= 4'h0;
    end else begin
      request_reg <= request;
    end
  end

  // First stage of daisy chain (combinational)
  wire first_priority;
  wire first_to_second;
  
  assign first_priority = 1'b1;  // First stage always has priority
  assign first_to_second = first_priority & ~request_reg[0];
  
  // Second stage of daisy chain (combinational)
  wire second_to_third;
  wire third_to_fourth;
  
  assign second_to_third = first_to_second & ~request_reg[1];
  assign third_to_fourth = second_to_third & ~request_reg[2];
  
  // Grant logic directly from combinational chain values
  always @(posedge clk) begin
    if (reset) begin
      grant <= 4'h0;
    end else begin
      grant[0] <= request_reg[0] & first_priority;
      grant[1] <= request_reg[1] & first_to_second;
      grant[2] <= request_reg[2] & second_to_third;
      grant[3] <= request_reg[3] & third_to_fourth;
    end
  end
endmodule