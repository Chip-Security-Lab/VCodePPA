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
  
  // Kogge-Stone adder implementation
  function [15:0] kogge_stone_adder;
    input [15:0] a, b;
    reg [15:0] p, g;
    reg [15:0] p1, g1;
    reg [15:0] p2, g2;
    reg [15:0] p3, g3;
    reg [15:0] p4, g4;
    reg [15:0] sum;
    begin
      // Generate and propagate signals
      p = a ^ b;
      g = a & b;
      
      // First stage
      p1[0] = p[0];
      g1[0] = g[0];
      p1[1] = p[1] & p[0];
      g1[1] = g[1] | (p[1] & g[0]);
      
      // Second stage
      p2[0] = p1[0];
      g2[0] = g1[0];
      p2[1] = p1[1];
      g2[1] = g1[1];
      p2[2] = p[2] & p1[1];
      g2[2] = g[2] | (p[2] & g1[1]);
      p2[3] = p[3] & p[2] & p1[1];
      g2[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g1[1]);
      
      // Third stage
      p3[0] = p2[0];
      g3[0] = g2[0];
      p3[1] = p2[1];
      g3[1] = g2[1];
      p3[2] = p2[2];
      g3[2] = g2[2];
      p3[3] = p2[3];
      g3[3] = g2[3];
      p3[4] = p[4] & p2[3];
      g3[4] = g[4] | (p[4] & g2[3]);
      p3[5] = p[5] & p[4] & p2[3];
      g3[5] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g2[3]);
      p3[6] = p[6] & p[5] & p[4] & p2[3];
      g3[6] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g2[3]);
      p3[7] = p[7] & p[6] & p[5] & p[4] & p2[3];
      g3[7] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g2[3]);
      
      // Fourth stage
      p4[0] = p3[0];
      g4[0] = g3[0];
      p4[1] = p3[1];
      g4[1] = g3[1];
      p4[2] = p3[2];
      g4[2] = g3[2];
      p4[3] = p3[3];
      g4[3] = g3[3];
      p4[4] = p3[4];
      g4[4] = g3[4];
      p4[5] = p3[5];
      g4[5] = g3[5];
      p4[6] = p3[6];
      g4[6] = g3[6];
      p4[7] = p3[7];
      g4[7] = g3[7];
      p4[8] = p[8] & p3[7];
      g4[8] = g[8] | (p[8] & g3[7]);
      p4[9] = p[9] & p[8] & p3[7];
      g4[9] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & g3[7]);
      p4[10] = p[10] & p[9] & p[8] & p3[7];
      g4[10] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | (p[10] & p[9] & p[8] & g3[7]);
      p4[11] = p[11] & p[10] & p[9] & p[8] & p3[7];
      g4[11] = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]) | (p[11] & p[10] & p[9] & p[8] & g3[7]);
      p4[12] = p[12] & p[11] & p[10] & p[9] & p[8] & p3[7];
      g4[12] = g[12] | (p[12] & g[11]) | (p[12] & p[11] & g[10]) | (p[12] & p[11] & p[10] & g[9]) | (p[12] & p[11] & p[10] & p[9] & g[8]) | (p[12] & p[11] & p[10] & p[9] & p[8] & g3[7]);
      p4[13] = p[13] & p[12] & p[11] & p[10] & p[9] & p[8] & p3[7];
      g4[13] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & g[11]) | (p[13] & p[12] & p[11] & g[10]) | (p[13] & p[12] & p[11] & p[10] & g[9]) | (p[13] & p[12] & p[11] & p[10] & p[9] & g[8]) | (p[13] & p[12] & p[11] & p[10] & p[9] & p[8] & g3[7]);
      p4[14] = p[14] & p[13] & p[12] & p[11] & p[10] & p[9] & p[8] & p3[7];
      g4[14] = g[14] | (p[14] & g[13]) | (p[14] & p[13] & g[12]) | (p[14] & p[13] & p[12] & g[11]) | (p[14] & p[13] & p[12] & p[11] & g[10]) | (p[14] & p[13] & p[12] & p[11] & p[10] & g[9]) | (p[14] & p[13] & p[12] & p[11] & p[10] & p[9] & g[8]) | (p[14] & p[13] & p[12] & p[11] & p[10] & p[9] & p[8] & g3[7]);
      p4[15] = p[15] & p[14] & p[13] & p[12] & p[11] & p[10] & p[9] & p[8] & p3[7];
      g4[15] = g[15] | (p[15] & g[14]) | (p[15] & p[14] & g[13]) | (p[15] & p[14] & p[13] & g[12]) | (p[15] & p[14] & p[13] & p[12] & g[11]) | (p[15] & p[14] & p[13] & p[12] & p[11] & g[10]) | (p[15] & p[14] & p[13] & p[12] & p[11] & p[10] & g[9]) | (p[15] & p[14] & p[13] & p[12] & p[11] & p[10] & p[9] & p[8] & g3[7]);
      
      // Final sum calculation
      sum[0] = p[0];
      sum[1] = p[1] ^ g4[0];
      sum[2] = p[2] ^ g4[1];
      sum[3] = p[3] ^ g4[2];
      sum[4] = p[4] ^ g4[3];
      sum[5] = p[5] ^ g4[4];
      sum[6] = p[6] ^ g4[5];
      sum[7] = p[7] ^ g4[6];
      sum[8] = p[8] ^ g4[7];
      sum[9] = p[9] ^ g4[8];
      sum[10] = p[10] ^ g4[9];
      sum[11] = p[11] ^ g4[10];
      sum[12] = p[12] ^ g4[11];
      sum[13] = p[13] ^ g4[12];
      sum[14] = p[14] ^ g4[13];
      sum[15] = p[15] ^ g4[14];
      
      kogge_stone_adder = sum;
    end
  endfunction
  
  // CRC-16-CCITT polynomial: x^16 + x^12 + x^5 + 1
  function [15:0] update_crc;
    input [15:0] crc;
    input [7:0] data;
    reg [15:0] newcrc;
    integer i;
    begin
      newcrc = crc;
      for (i = 0; i < 8; i = i + 1) begin
        if ((newcrc[15] ^ data[i]) == 1'b1)
          newcrc = kogge_stone_adder((newcrc << 1), 16'h1021);
        else
          newcrc = newcrc << 1;
      end
      update_crc = newcrc;
    end
  endfunction

  // State machine control
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
    end else begin
      if (sot) begin
        state <= 4'd1;
      end else if (eot && state == 4'd1) begin
        state <= 4'd0;
      end
    end
  end

  // CRC register update
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc_reg <= 16'hFFFF;
    end else begin
      if (sot) begin
        crc_reg <= 16'hFFFF;
      end else if (data_valid && state == 4'd1) begin
        crc_reg <= update_crc(crc_reg, data_in);
      end
    end
  end

  // CRC output and valid signal generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc_out <= 16'h0000;
      crc_valid <= 1'b0;
    end else begin
      crc_valid <= 1'b0;
      if (eot && state == 4'd1) begin
        crc_out <= crc_reg;
        crc_valid <= 1'b1;
      end
    end
  end

endmodule