//SystemVerilog
module wallace_multiplier(
  input [7:0] a,
  input [7:0] b,
  output [15:0] product
);

  // Partial products generation
  wire [7:0][7:0] pp;
  genvar i, j;
  generate
    for (i = 0; i < 8; i = i + 1) begin : gen_pp
      for (j = 0; j < 8; j = j + 1) begin : gen_pp_col
        assign pp[i][j] = a[i] & b[j];
      end
    end
  endgenerate

  // First stage of reduction
  wire [7:0] s1, c1;
  wire [6:0] s2, c2;
  wire [5:0] s3, c3;
  wire [4:0] s4, c4;
  wire [3:0] s5, c5;
  wire [2:0] s6, c6;
  wire [1:0] s7, c7;
  wire s8, c8;

  // First level of reduction
  full_adder fa1_0(pp[0][0], pp[1][0], pp[2][0], s1[0], c1[0]);
  full_adder fa1_1(pp[0][1], pp[1][1], pp[2][1], s1[1], c1[1]);
  full_adder fa1_2(pp[0][2], pp[1][2], pp[2][2], s1[2], c1[2]);
  full_adder fa1_3(pp[0][3], pp[1][3], pp[2][3], s1[3], c1[3]);
  full_adder fa1_4(pp[0][4], pp[1][4], pp[2][4], s1[4], c1[4]);
  full_adder fa1_5(pp[0][5], pp[1][5], pp[2][5], s1[5], c1[5]);
  full_adder fa1_6(pp[0][6], pp[1][6], pp[2][6], s1[6], c1[6]);
  full_adder fa1_7(pp[0][7], pp[1][7], pp[2][7], s1[7], c1[7]);

  // Final addition
  wire [15:0] sum, carry;
  assign sum[0] = pp[0][0];
  assign carry[0] = 1'b0;
  
  genvar k;
  generate
    for (k = 1; k < 16; k = k + 1) begin : gen_final_add
      full_adder fa_final(sum[k-1], carry[k-1], pp[k][0], sum[k], carry[k]);
    end
  endgenerate

  assign product = sum + (carry << 1);

endmodule

module full_adder(
  input a, b, cin,
  output sum, cout
);
  assign sum = a ^ b ^ cin;
  assign cout = (a & b) | (cin & (a ^ b));
endmodule

module mask_arbiter_combinational(
  input [7:0] i_req,
  input [7:0] i_mask,
  output [7:0] o_masked_req
);
  wire [15:0] mult_result;
  
  wallace_multiplier mult(
    .a(i_req),
    .b(i_mask),
    .product(mult_result)
  );
  
  assign o_masked_req = mult_result[7:0];
endmodule

module mask_arbiter_sequential(
  input i_clk,
  input i_rstn,
  input [7:0] i_masked_req,
  output reg [7:0] o_grant
);
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) o_grant <= 8'h0;
    else begin
      o_grant <= 8'h0;
      casez (i_masked_req)
        8'b1???????: o_grant <= 8'b10000000;
        8'b01??????: o_grant <= 8'b01000000;
        8'b001?????: o_grant <= 8'b00100000;
        8'b0001????: o_grant <= 8'b00010000;
        8'b00001???: o_grant <= 8'b00001000;
        8'b000001??: o_grant <= 8'b00000100;
        8'b0000001?: o_grant <= 8'b00000010;
        8'b00000001: o_grant <= 8'b00000001;
        default: o_grant <= 8'h0;
      endcase
    end
  end
endmodule

module mask_arbiter(
  input i_clk,
  input i_rstn,
  input [7:0] i_req,
  input [7:0] i_mask,
  output [7:0] o_grant
);
  wire [7:0] masked_req;
  
  mask_arbiter_combinational comb_logic(
    .i_req(i_req),
    .i_mask(i_mask),
    .o_masked_req(masked_req)
  );
  
  mask_arbiter_sequential seq_logic(
    .i_clk(i_clk),
    .i_rstn(i_rstn),
    .i_masked_req(masked_req),
    .o_grant(o_grant)
  );
endmodule