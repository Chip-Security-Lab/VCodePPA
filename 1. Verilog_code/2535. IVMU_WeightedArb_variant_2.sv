//SystemVerilog
module IVMU_WeightedArb #(parameter W1=3, W2=2, W3=1) (
    input clk,
    input irq1, irq2, irq3,
    output reg [1:0] sel
);

reg [7:0] cnt1;
reg [7:0] cnt2;
reg [7:0] cnt3;

// Registers to buffer comparison results derived from cnt1, cnt2, cnt3
// These registers break the critical path from cnt registers to sel register
reg gt12_pipe; // Pipelined result of cnt1 > cnt2
reg gt13_pipe; // Pipelined result of cnt1 > cnt3
reg gt23_pipe; // Pipelined result of cnt2 > cnt3

// Wires for Carry-Lookahead Adder 1 (cnt1 + W1)
wire [7:0] cla1_p, cla1_g;
wire [3:0] cla1_gp, cla1_gg; // Group propagate and generate (2-bit groups)
wire [8:0] cla1_c; // Carries (cla1_c[0] is cin, cla1_c[8] is cout)
wire [7:0] cla1_sum;

// CLA 1: Bitwise Propagate (P) and Generate (G)
genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin : cla1_bit_pg
    assign cla1_p[i] = cnt1[i] ^ W1[i];
    assign cla1_g[i] = cnt1[i] & W1[i];
  end
endgenerate

// CLA 1: Group Propagate (GP) and Generate (GG) for 2-bit groups
assign cla1_gp[0] = cla1_p[1] & cla1_p[0];
assign cla1_gg[0] = cla1_g[1] | (cla1_p[1] & cla1_g[0]);
assign cla1_gp[1] = cla1_p[3] & cla1_p[2];
assign cla1_gg[1] = cla1_g[3] | (cla1_p[3] & cla1_g[2]);
assign cla1_gp[2] = cla1_p[5] & cla1_p[4];
assign cla1_gg[2] = cla1_g[5] | (cla1_p[5] & cla1_g[4]);
assign cla1_gp[3] = cla1_p[7] & cla1_p[6];
assign cla1_gg[3] = cla1_g[7] | (cla1_p[7] & cla1_g[6]);

// CLA 1: Carries
assign cla1_c[0] = 1'b0; // Cin = 0 for addition
assign cla1_c[1] = cla1_g[0] | (cla1_p[0] & cla1_c[0]);
assign cla1_c[2] = cla1_gg[0] | (cla1_gp[0] & cla1_c[0]); // Carry out of group 0
assign cla1_c[3] = cla1_g[2] | (cla1_p[2] & cla1_c[2]);
assign cla1_c[4] = cla1_gg[1] | (cla1_gp[1] & cla1_c[2]); // Carry out of group 1
assign cla1_c[5] = cla1_g[4] | (cla1_p[4] & cla1_c[4]);
assign cla1_c[6] = cla1_gg[2] | (cla1_gp[2] & cla1_c[4]); // Carry out of group 2
assign cla1_c[7] = cla1_g[6] | (cla1_p[6] & cla1_c[6]);
assign cla1_c[8] = cla1_gg[3] | (cla1_gp[3] & cla1_c[6]); // Carry out of group 3 (overall cout)

// CLA 1: Sum bits
generate
  for (i = 0; i < 8; i = i + 1) begin : cla1_bit_sum
    assign cla1_sum[i] = cla1_p[i] ^ cla1_c[i];
  end
endgenerate


// Wires for Carry-Lookahead Adder 2 (cnt2 + W2)
wire [7:0] cla2_p, cla2_g;
wire [3:0] cla2_gp, cla2_gg; // Group propagate and generate (2-bit groups)
wire [8:0] cla2_c; // Carries (cla2_c[0] is cin, cla2_c[8] is cout)
wire [7:0] cla2_sum;

// CLA 2: Bitwise Propagate (P) and Generate (G)
generate
  for (i = 0; i < 8; i = i + 1) begin : cla2_bit_pg
    assign cla2_p[i] = cnt2[i] ^ W2[i];
    assign cla2_g[i] = cnt2[i] & W2[i];
  end
endgenerate

// CLA 2: Group Propagate (GP) and Generate (GG) for 2-bit groups
assign cla2_gp[0] = cla2_p[1] & cla2_p[0];
assign cla2_gg[0] = cla2_g[1] | (cla2_p[1] & cla2_g[0]);
assign cla2_gp[1] = cla2_p[3] & cla2_p[2];
assign cla2_gg[1] = cla2_g[3] | (cla2_p[3] & cla2_g[2]);
assign cla2_gp[2] = cla2_p[5] & cla2_p[4];
assign cla2_gg[2] = cla2_g[5] | (cla2_p[5] & cla2_g[4]);
assign cla2_gp[3] = cla2_p[7] & cla2_p[6];
assign cla2_gg[3] = cla2_g[7] | (cla2_p[7] & cla2_g[6]);

// CLA 2: Carries
assign cla2_c[0] = 1'b0; // Cin = 0 for addition
assign cla2_c[1] = cla2_g[0] | (cla2_p[0] & cla2_c[0]);
assign cla2_c[2] = cla2_gg[0] | (cla2_gp[0] & cla2_c[0]); // Carry out of group 0
assign cla2_c[3] = cla2_g[2] | (cla2_p[2] & cla2_c[2]);
assign cla2_c[4] = cla2_gg[1] | (cla2_gp[1] & cla2_c[2]); // Carry out of group 1
assign cla2_c[5] = cla2_g[4] | (cla2_p[4] & cla2_c[4]);
assign cla2_c[6] = cla2_gg[2] | (cla2_gp[2] & cla2_c[4]); // Carry out of group 2
assign cla2_c[7] = cla2_g[6] | (cla2_p[6] & cla2_c[6]);
assign cla2_c[8] = cla2_gg[3] | (cla2_gp[3] & cla2_c[6]); // Carry out of group 3 (overall cout)

// CLA 2: Sum bits
generate
  for (i = 0; i < 8; i = i + 1) begin : cla2_bit_sum
    assign cla2_sum[i] = cla2_p[i] ^ cla2_c[i];
  end
endgenerate


// Wires for Carry-Lookahead Adder 3 (cnt3 + W3)
wire [7:0] cla3_p, cla3_g;
wire [3:0] cla3_gp, cla3_gg; // Group propagate and generate (2-bit groups)
wire [8:0] cla3_c; // Carries (cla3_c[0] is cin, cla3_c[8] is cout)
wire [7:0] cla3_sum;

// CLA 3: Bitwise Propagate (P) and Generate (G)
generate
  for (i = 0; i < 8; i = i + 1) begin : cla3_bit_pg
    assign cla3_p[i] = cnt3[i] ^ W3[i];
    assign cla3_g[i] = cnt3[i] & W3[i];
  end
endgenerate

// CLA 3: Group Propagate (GP) and Generate (GG) for 2-bit groups
assign cla3_gp[0] = cla3_p[1] & cla3_p[0];
assign cla3_gg[0] = cla3_g[1] | (cla3_p[1] & cla3_g[0]);
assign cla3_gp[1] = cla3_p[3] & cla3_p[2];
assign cla3_gg[1] = cla3_g[3] | (cla3_p[3] & cla3_g[2]);
assign cla3_gp[2] = cla3_p[5] & cla3_p[4];
assign cla3_gg[2] = cla3_g[5] | (cla3_p[5] & cla3_g[4]);
assign cla3_gp[3] = cla3_p[7] & cla3_p[6];
assign cla3_gg[3] = cla3_g[7] | (cla3_p[7] & cla3_g[6]);

// CLA 3: Carries
assign cla3_c[0] = 1'b0; // Cin = 0 for addition
assign cla3_c[1] = cla3_g[0] | (cla3_p[0] & cla3_c[0]);
assign cla3_c[2] = cla3_gg[0] | (cla3_gp[0] & cla3_c[0]); // Carry out of group 0
assign cla3_c[3] = cla3_g[2] | (cla3_p[2] & cla3_c[2]);
assign cla3_c[4] = cla3_gg[1] | (cla3_gp[1] & cla3_c[2]); // Carry out of group 1
assign cla3_c[5] = cla3_g[4] | (cla3_p[4] & cla3_c[4]);
assign cla3_c[6] = cla3_gg[2] | (cla3_gp[2] & cla3_c[4]); // Carry out of group 2
assign cla3_c[7] = cla3_g[6] | (cla3_p[6] & cla3_c[6]);
assign cla3_c[8] = cla3_gg[3] | (cla3_gp[3] & cla3_c[6]); // Carry out of group 3 (overall cout)

// CLA 3: Sum bits
generate
  for (i = 0; i < 8; i = i + 1) begin : cla3_bit_sum
    assign cla3_sum[i] = cla3_p[i] ^ cla3_c[i];
  end
endgenerate


always @(posedge clk) begin
    // Counter updates - Using CLA sums
    if (irq1) begin
        cnt1 <= cla1_sum; // Use CLA output
    end else begin
        cnt1 <= 0;
    end

    if (irq2) begin
        cnt2 <= cla2_sum; // Use CLA output
    end else begin
        cnt2 <= 0;
    end

    if (irq3) begin
        cnt3 <= cla3_sum; // Use CLA output
    end else begin
        cnt3 <= 0;
    end

    // Pipeline stage 1: Compute comparisons and register them
    // Driven by cnt outputs, reducing the combinational load on cnt outputs
    gt12_pipe <= (cnt1 > cnt2);
    gt13_pipe <= (cnt1 > cnt3);
    gt23_pipe <= (cnt2 > cnt3);

    // Pipeline stage 2: Compute selection based on registered comparisons
    // Driven by pipelined comparison results (low fanout) - Transformed from ? : to if-else
    if (gt12_pipe && gt13_pipe) begin
        sel <= 2'd0; // Corresponds to index 0
    end else begin
        if (gt23_pipe) begin
            sel <= 2'd1; // Corresponds to index 1
        end else begin
            sel <= 2'd2; // Corresponds to index 2
        end
    end
end

endmodule