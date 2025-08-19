//SystemVerilog
module fsm_parity_gen(
  input clk, rst, start,
  input [15:0] data_in,
  output reg valid, 
  output reg parity_bit
);
  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  reg [1:0] state;
  reg [3:0] bit_pos;
  
  wire [15:0] increment;
  wire [15:0] sum;
  wire cout;
  
  assign increment = {15'b0, 1'b1};
  
  han_carlson_adder hca(
    .a({12'b0, bit_pos}),
    .b(increment),
    .sum(sum),
    .cout(cout)
  );
  
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      bit_pos <= 4'd0;
      parity_bit <= 1'b0;
      valid <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= COMPUTE;
            bit_pos <= 4'd0;
            parity_bit <= 1'b0;
            valid <= 1'b0;
          end
        end
        COMPUTE: begin
          if (bit_pos < 4'd15) begin
            parity_bit <= parity_bit ^ data_in[bit_pos];
            bit_pos <= sum[3:0];
          end else begin
            parity_bit <= parity_bit ^ data_in[15];
            state <= DONE;
          end
        end
        DONE: begin
          valid <= 1'b1;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule

module han_carlson_adder(
  input [15:0] a,
  input [15:0] b,
  output [15:0] sum,
  output cout
);
  wire [15:0] g, p;
  wire [15:0] g_temp [0:3];
  wire [15:0] p_temp [0:3];
  
  // Initial generate and propagate signals
  assign g[0] = a[0] & b[0];
  assign p[0] = a[0] ^ b[0];
  assign g[1] = a[1] & b[1];
  assign p[1] = a[1] ^ b[1];
  assign g[2] = a[2] & b[2];
  assign p[2] = a[2] ^ b[2];
  assign g[3] = a[3] & b[3];
  assign p[3] = a[3] ^ b[3];
  assign g[4] = a[4] & b[4];
  assign p[4] = a[4] ^ b[4];
  assign g[5] = a[5] & b[5];
  assign p[5] = a[5] ^ b[5];
  assign g[6] = a[6] & b[6];
  assign p[6] = a[6] ^ b[6];
  assign g[7] = a[7] & b[7];
  assign p[7] = a[7] ^ b[7];
  assign g[8] = a[8] & b[8];
  assign p[8] = a[8] ^ b[8];
  assign g[9] = a[9] & b[9];
  assign p[9] = a[9] ^ b[9];
  assign g[10] = a[10] & b[10];
  assign p[10] = a[10] ^ b[10];
  assign g[11] = a[11] & b[11];
  assign p[11] = a[11] ^ b[11];
  assign g[12] = a[12] & b[12];
  assign p[12] = a[12] ^ b[12];
  assign g[13] = a[13] & b[13];
  assign p[13] = a[13] ^ b[13];
  assign g[14] = a[14] & b[14];
  assign p[14] = a[14] ^ b[14];
  assign g[15] = a[15] & b[15];
  assign p[15] = a[15] ^ b[15];
  
  // Initial values
  assign g_temp[0] = g;
  assign p_temp[0] = p;
  
  // Stage 1 (distance 1)
  assign g_temp[1][0] = g_temp[0][0];
  assign p_temp[1][0] = p_temp[0][0];
  assign g_temp[1][1] = g_temp[0][1];
  assign p_temp[1][1] = p_temp[0][1];
  assign g_temp[1][2] = g_temp[0][2] | (p_temp[0][2] & g_temp[0][1]);
  assign p_temp[1][2] = p_temp[0][2] & p_temp[0][1];
  assign g_temp[1][3] = g_temp[0][3];
  assign p_temp[1][3] = p_temp[0][3];
  assign g_temp[1][4] = g_temp[0][4] | (p_temp[0][4] & g_temp[0][3]);
  assign p_temp[1][4] = p_temp[0][4] & p_temp[0][3];
  assign g_temp[1][5] = g_temp[0][5];
  assign p_temp[1][5] = p_temp[0][5];
  assign g_temp[1][6] = g_temp[0][6] | (p_temp[0][6] & g_temp[0][5]);
  assign p_temp[1][6] = p_temp[0][6] & p_temp[0][5];
  assign g_temp[1][7] = g_temp[0][7];
  assign p_temp[1][7] = p_temp[0][7];
  assign g_temp[1][8] = g_temp[0][8] | (p_temp[0][8] & g_temp[0][7]);
  assign p_temp[1][8] = p_temp[0][8] & p_temp[0][7];
  assign g_temp[1][9] = g_temp[0][9];
  assign p_temp[1][9] = p_temp[0][9];
  assign g_temp[1][10] = g_temp[0][10] | (p_temp[0][10] & g_temp[0][9]);
  assign p_temp[1][10] = p_temp[0][10] & p_temp[0][9];
  assign g_temp[1][11] = g_temp[0][11];
  assign p_temp[1][11] = p_temp[0][11];
  assign g_temp[1][12] = g_temp[0][12] | (p_temp[0][12] & g_temp[0][11]);
  assign p_temp[1][12] = p_temp[0][12] & p_temp[0][11];
  assign g_temp[1][13] = g_temp[0][13];
  assign p_temp[1][13] = p_temp[0][13];
  assign g_temp[1][14] = g_temp[0][14] | (p_temp[0][14] & g_temp[0][13]);
  assign p_temp[1][14] = p_temp[0][14] & p_temp[0][13];
  assign g_temp[1][15] = g_temp[0][15];
  assign p_temp[1][15] = p_temp[0][15];
  
  // Stage 2 (distance 2)
  assign g_temp[2][0] = g_temp[1][0];
  assign p_temp[2][0] = p_temp[1][0];
  assign g_temp[2][1] = g_temp[1][1];
  assign p_temp[2][1] = p_temp[1][1];
  assign g_temp[2][2] = g_temp[1][2];
  assign p_temp[2][2] = p_temp[1][2];
  assign g_temp[2][3] = g_temp[1][3];
  assign p_temp[2][3] = p_temp[1][3];
  assign g_temp[2][4] = g_temp[1][4] | (p_temp[1][4] & g_temp[1][2]);
  assign p_temp[2][4] = p_temp[1][4] & p_temp[1][2];
  assign g_temp[2][5] = g_temp[1][5];
  assign p_temp[2][5] = p_temp[1][5];
  assign g_temp[2][6] = g_temp[1][6] | (p_temp[1][6] & g_temp[1][4]);
  assign p_temp[2][6] = p_temp[1][6] & p_temp[1][4];
  assign g_temp[2][7] = g_temp[1][7];
  assign p_temp[2][7] = p_temp[1][7];
  assign g_temp[2][8] = g_temp[1][8] | (p_temp[1][8] & g_temp[1][6]);
  assign p_temp[2][8] = p_temp[1][8] & p_temp[1][6];
  assign g_temp[2][9] = g_temp[1][9];
  assign p_temp[2][9] = p_temp[1][9];
  assign g_temp[2][10] = g_temp[1][10] | (p_temp[1][10] & g_temp[1][8]);
  assign p_temp[2][10] = p_temp[1][10] & p_temp[1][8];
  assign g_temp[2][11] = g_temp[1][11];
  assign p_temp[2][11] = p_temp[1][11];
  assign g_temp[2][12] = g_temp[1][12] | (p_temp[1][12] & g_temp[1][10]);
  assign p_temp[2][12] = p_temp[1][12] & p_temp[1][10];
  assign g_temp[2][13] = g_temp[1][13];
  assign p_temp[2][13] = p_temp[1][13];
  assign g_temp[2][14] = g_temp[1][14] | (p_temp[1][14] & g_temp[1][12]);
  assign p_temp[2][14] = p_temp[1][14] & p_temp[1][12];
  assign g_temp[2][15] = g_temp[1][15];
  assign p_temp[2][15] = p_temp[1][15];
  
  // Stage 3 (distance 4)
  assign g_temp[3][0] = g_temp[2][0];
  assign p_temp[3][0] = p_temp[2][0];
  assign g_temp[3][1] = g_temp[2][1];
  assign p_temp[3][1] = p_temp[2][1];
  assign g_temp[3][2] = g_temp[2][2];
  assign p_temp[3][2] = p_temp[2][2];
  assign g_temp[3][3] = g_temp[2][3];
  assign p_temp[3][3] = p_temp[2][3];
  assign g_temp[3][4] = g_temp[2][4];
  assign p_temp[3][4] = p_temp[2][4];
  assign g_temp[3][5] = g_temp[2][5];
  assign p_temp[3][5] = p_temp[2][5];
  assign g_temp[3][6] = g_temp[2][6];
  assign p_temp[3][6] = p_temp[2][6];
  assign g_temp[3][7] = g_temp[2][7];
  assign p_temp[3][7] = p_temp[2][7];
  assign g_temp[3][8] = g_temp[2][8] | (p_temp[2][8] & g_temp[2][4]);
  assign p_temp[3][8] = p_temp[2][8] & p_temp[2][4];
  assign g_temp[3][9] = g_temp[2][9];
  assign p_temp[3][9] = p_temp[2][9];
  assign g_temp[3][10] = g_temp[2][10] | (p_temp[2][10] & g_temp[2][6]);
  assign p_temp[3][10] = p_temp[2][10] & p_temp[2][6];
  assign g_temp[3][11] = g_temp[2][11];
  assign p_temp[3][11] = p_temp[2][11];
  assign g_temp[3][12] = g_temp[2][12] | (p_temp[2][12] & g_temp[2][8]);
  assign p_temp[3][12] = p_temp[2][12] & p_temp[2][8];
  assign g_temp[3][13] = g_temp[2][13];
  assign p_temp[3][13] = p_temp[2][13];
  assign g_temp[3][14] = g_temp[2][14] | (p_temp[2][14] & g_temp[2][10]);
  assign p_temp[3][14] = p_temp[2][14] & p_temp[2][10];
  assign g_temp[3][15] = g_temp[2][15];
  assign p_temp[3][15] = p_temp[2][15];
  
  // Carry computation
  wire [15:0] carry;
  assign carry[0] = 1'b0;
  assign carry[1] = g[0] | (p[0] & carry[0]);
  assign carry[2] = g_temp[3][0];
  assign carry[3] = g[2] | (p[2] & carry[2]);
  assign carry[4] = g_temp[3][2];
  assign carry[5] = g[4] | (p[4] & carry[4]);
  assign carry[6] = g_temp[3][4];
  assign carry[7] = g[6] | (p[6] & carry[6]);
  assign carry[8] = g_temp[3][6];
  assign carry[9] = g[8] | (p[8] & carry[8]);
  assign carry[10] = g_temp[3][8];
  assign carry[11] = g[10] | (p[10] & carry[10]);
  assign carry[12] = g_temp[3][10];
  assign carry[13] = g[12] | (p[12] & carry[12]);
  assign carry[14] = g_temp[3][12];
  assign carry[15] = g[14] | (p[14] & carry[14]);
  
  // Final sum computation
  assign sum[0] = p[0] ^ carry[0];
  assign sum[1] = p[1] ^ carry[1];
  assign sum[2] = p[2] ^ carry[2];
  assign sum[3] = p[3] ^ carry[3];
  assign sum[4] = p[4] ^ carry[4];
  assign sum[5] = p[5] ^ carry[5];
  assign sum[6] = p[6] ^ carry[6];
  assign sum[7] = p[7] ^ carry[7];
  assign sum[8] = p[8] ^ carry[8];
  assign sum[9] = p[9] ^ carry[9];
  assign sum[10] = p[10] ^ carry[10];
  assign sum[11] = p[11] ^ carry[11];
  assign sum[12] = p[12] ^ carry[12];
  assign sum[13] = p[13] ^ carry[13];
  assign sum[14] = p[14] ^ carry[14];
  assign sum[15] = p[15] ^ carry[15];
  
  assign cout = g[15] | (p[15] & carry[15]);
endmodule