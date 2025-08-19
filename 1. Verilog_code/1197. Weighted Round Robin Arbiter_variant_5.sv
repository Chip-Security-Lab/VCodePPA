//SystemVerilog
module weighted_rr_arbiter(
  input clk, rst,
  input [2:0] req,
  input [1:0] weights [2:0],  // Weight for each requester
  output reg [2:0] grant
);
  reg [2:0] count [2:0];
  reg [1:0] current;
  reg [2:0] req_reg;
  reg [1:0] weights_reg [2:0];
  
  // Register inputs to improve timing at input pins
  always @(posedge clk) begin
    if (rst) begin
      req_reg <= 3'd0;
      weights_reg[0] <= 2'd0;
      weights_reg[1] <= 2'd0;
      weights_reg[2] <= 2'd0;
    end else begin
      req_reg <= req;
      weights_reg[0] <= weights[0];
      weights_reg[1] <= weights[1];
      weights_reg[2] <= weights[2];
    end
  end
  
  // Next state calculation using registered inputs
  wire [1:0] next_current;
  assign next_current = (req_reg[current] && count[current] < weights_reg[current]) ? 
                         current : 
                         (current == 2'd2) ? 2'd0 : (current + 2'd1);
  
  // Main state update logic
  always @(posedge clk) begin
    if (rst) begin
      current <= 2'd0;
      grant <= 3'd0;
      count[0] <= 3'd0; 
      count[1] <= 3'd0; 
      count[2] <= 3'd0;
    end else begin
      grant <= 3'd0;
      
      if (req_reg[current] && count[current] < weights_reg[current]) begin
        grant[current] <= 1'b1;
        count[current] <= count[current] + 3'd1;
      end else begin
        count[current] <= 3'd0;
        current <= next_current;
      end
    end
  end
endmodule