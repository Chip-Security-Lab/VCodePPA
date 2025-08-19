//SystemVerilog
module sliding_window_parity(
  input clk, rst_n,
  input data_bit,
  input [2:0] window_size,
  input data_valid,      // Sender indicates data is valid
  output reg data_ready, // Receiver indicates ready to accept data
  output reg window_parity
);
  reg [7:0] shift_reg;
  reg [7:0] parity_mask;
  reg parity_calc;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 8'h00;
      window_parity <= 1'b0;
      data_ready <= 1'b1;
      parity_calc <= 1'b0;
    end else begin
      // Set ready based on current state
      data_ready <= 1'b1;
      
      // Only process data when valid and ready are both high
      if (data_valid && data_ready) begin
        shift_reg <= {shift_reg[6:0], data_bit};
        parity_calc <= ^(shift_reg[6:0] & parity_mask[7:1]) ^ (data_bit & parity_mask[0]);
        window_parity <= parity_calc;
      end
    end
  end
  
  // Generate mask based on window size - combinational logic
  always @(*) begin
    parity_mask = 8'h00;
    case(window_size)
      3'd1: parity_mask = 8'h01;
      3'd2: parity_mask = 8'h03;
      3'd3: parity_mask = 8'h07;
      3'd4: parity_mask = 8'h0F;
      3'd5: parity_mask = 8'h1F;
      3'd6: parity_mask = 8'h3F;
      3'd7: parity_mask = 8'h7F;
      3'd0: parity_mask = 8'hFF;
    endcase
  end
endmodule