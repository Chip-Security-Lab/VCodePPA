//SystemVerilog
module HanCarlsonAdder16 (
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum,
    output cout
);
    wire [15:0] p, g;
    wire [7:0] p2, g2;
    wire [3:0] p4, g4;
    wire [1:0] p8, g8;
    wire p16, g16;
    
    // Generate P and G
    assign p = a ^ b;
    assign g = a & b;
    
    // First level
    assign p2[0] = p[1] & p[0];
    assign g2[0] = g[1] | (p[1] & g[0]);
    assign p2[1] = p[3] & p[2];
    assign g2[1] = g[3] | (p[3] & g[2]);
    assign p2[2] = p[5] & p[4];
    assign g2[2] = g[5] | (p[5] & g[4]);
    assign p2[3] = p[7] & p[6];
    assign g2[3] = g[7] | (p[7] & g[6]);
    assign p2[4] = p[9] & p[8];
    assign g2[4] = g[9] | (p[9] & g[8]);
    assign p2[5] = p[11] & p[10];
    assign g2[5] = g[11] | (p[11] & g[10]);
    assign p2[6] = p[13] & p[12];
    assign g2[6] = g[13] | (p[13] & g[12]);
    assign p2[7] = p[15] & p[14];
    assign g2[7] = g[15] | (p[15] & g[14]);
    
    // Second level
    assign p4[0] = p2[1] & p2[0];
    assign g4[0] = g2[1] | (p2[1] & g2[0]);
    assign p4[1] = p2[3] & p2[2];
    assign g4[1] = g2[3] | (p2[3] & g2[2]);
    assign p4[2] = p2[5] & p2[4];
    assign g4[2] = g2[5] | (p2[5] & g2[4]);
    assign p4[3] = p2[7] & p2[6];
    assign g4[3] = g2[7] | (p2[7] & g2[6]);
    
    // Third level
    assign p8[0] = p4[1] & p4[0];
    assign g8[0] = g4[1] | (p4[1] & g4[0]);
    assign p8[1] = p4[3] & p4[2];
    assign g8[1] = g4[3] | (p4[3] & g4[2]);
    
    // Fourth level
    assign p16 = p8[1] & p8[0];
    assign g16 = g8[1] | (p8[1] & g8[0]);
    
    // Generate carry
    wire [15:0] c;
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g2[0] | (p2[0] & cin);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g4[0] | (p4[0] & cin);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g2[2] | (p2[2] & c[4]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g8[0] | (p8[0] & cin);
    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g2[4] | (p2[4] & c[8]);
    assign c[11] = g[10] | (p[10] & c[10]);
    assign c[12] = g4[2] | (p4[2] & c[8]);
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g2[6] | (p2[6] & c[12]);
    assign c[15] = g[14] | (p[14] & c[14]);
    
    // Generate sum
    assign sum = p ^ c;
    assign cout = g16 | (p16 & cin);
endmodule

module PulseWidthLatch (
    input clk,
    input req,
    output reg ack,
    output reg [15:0] width_count
);
    reg last_req;
    reg [15:0] count_reg;
    wire [15:0] next_count;
    wire cout;
    
    HanCarlsonAdder16 adder (
        .a(count_reg),
        .b(16'h0001),
        .cin(1'b0),
        .sum(next_count),
        .cout(cout)
    );
    
    always @(posedge clk) begin
        last_req <= req;
        if(req && !last_req) begin
            count_reg <= 0;
            ack <= 1'b1;
        end
        else if(req) begin
            count_reg <= next_count;
            ack <= 1'b1;
        end
        else begin
            ack <= 1'b0;
        end
        width_count <= count_reg;
    end
endmodule