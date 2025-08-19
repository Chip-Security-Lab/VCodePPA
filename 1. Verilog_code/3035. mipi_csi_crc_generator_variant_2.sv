//SystemVerilog
module mipi_csi_crc_generator (
  input wire clk, reset_n,
  input wire [7:0] data_in,
  input wire data_valid,
  input wire sot, eot,
  output reg [15:0] crc_out,
  output reg crc_valid
);

  reg [15:0] crc_reg;
  reg [3:0] state;
  
  function [15:0] update_crc;
    input [15:0] crc;
    input [7:0] data;
    reg [15:0] newcrc;
    reg [15:0] feedback;
    integer i;
    begin
      newcrc = crc;
      for (i = 0; i < 8; i = i + 1) begin
        feedback = newcrc[15] ^ data[i];
        newcrc = {newcrc[14:0], 1'b0};
        if (feedback) begin
          newcrc = newcrc ^ 16'h1021;
        end
      end
      update_crc = newcrc;
    end
  endfunction
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc_reg <= 16'hFFFF;
      crc_valid <= 1'b0;
      state <= 4'd0;
    end else begin
      crc_valid <= 1'b0;
      
      if (sot) begin
        crc_reg <= 16'hFFFF;
        state <= 4'd1;
      end else if (data_valid && state == 4'd1) begin
        crc_reg <= update_crc(crc_reg, data_in);
      end else if (eot && state == 4'd1) begin
        crc_out <= crc_reg;
        crc_valid <= 1'b1;
        state <= 4'd0;
      end
    end
  end
endmodule