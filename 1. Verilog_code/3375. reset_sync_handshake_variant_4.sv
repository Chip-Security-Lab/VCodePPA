//SystemVerilog IEEE-1364-2005
module reset_sync_handshake(
  input  wire clk,
  input  wire rst_n,
  input  wire rst_valid,
  output reg  rst_done
);
  reg sync_flop_1;
  reg sync_flop_2;
  
  // First stage register - moved closer to the inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_flop_1 <= 1'b0;
    end else if (rst_valid) begin
      sync_flop_1 <= 1'b1;
    end else begin
      sync_flop_1 <= sync_flop_1;
    end
  end
  
  // Second stage register - maintains signal propagation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_flop_2 <= 1'b0;
    end else begin
      sync_flop_2 <= sync_flop_1;
    end
  end
  
  // Output register - simplified logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_done <= 1'b0;
    end else begin
      rst_done <= sync_flop_2 & rst_valid;
    end
  end
endmodule