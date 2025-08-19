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
  reg [15:0] newcrc_buf;
  reg [2:0] i_buf;
  
  function [15:0] update_crc;
    input [15:0] crc;
    input [7:0] data;
    reg [15:0] newcrc;
    integer i;
    begin
      newcrc = crc;
      for (i = 0; i < 8; i = i + 1) begin
        if ((newcrc[15] ^ data[i]) == 1'b1)
          newcrc = (newcrc << 1) ^ 16'h1021;
        else
          newcrc = newcrc << 1;
      end
      update_crc = newcrc;
    end
  endfunction
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc_reg <= 16'hFFFF;
      crc_valid <= 1'b0;
      state <= 4'd0;
      newcrc_buf <= 16'h0;
      i_buf <= 3'd0;
    end else begin
      crc_valid <= 1'b0;
      
      case ({sot, data_valid, eot, state})
        5'b1000x: begin  // sot
          crc_reg <= 16'hFFFF;
          state <= 4'd1;
          newcrc_buf <= 16'h0;
          i_buf <= 3'd0;
        end
        5'b01001: begin  // data_valid && state == 1
          newcrc_buf <= update_crc(crc_reg, data_in);
          crc_reg <= newcrc_buf;
        end
        5'b00101: begin  // eot && state == 1
          crc_out <= crc_reg;
          crc_valid <= 1'b1;
          state <= 4'd0;
        end
        default: begin
          // Maintain current state
        end
      endcase
    end
  end
endmodule