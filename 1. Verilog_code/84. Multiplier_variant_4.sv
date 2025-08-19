//SystemVerilog
module HanCarlsonAdder8(
    input [7:0] a, b,
    input cin,
    input req,
    output reg ack,
    output reg [7:0] sum,
    output reg cout
);
    wire [7:0] p, g;
    wire [7:0] p_level1, g_level1;
    wire [7:0] p_level2, g_level2;
    wire [7:0] p_level3, g_level3;
    wire [7:0] c;
    wire [7:0] sum_next;
    wire cout_next;

    // Generate P and G
    assign p = a ^ b;
    assign g = a & b;

    // Level 1
    assign p_level1[0] = p[0];
    assign g_level1[0] = g[0];
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[2] = p[2] & p[1];
    assign g_level1[2] = g[2] | (p[2] & g[1]);
    assign p_level1[3] = p[3] & p[2];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[4] = p[4] & p[3];
    assign g_level1[4] = g[4] | (p[4] & g[3]);
    assign p_level1[5] = p[5] & p[4];
    assign g_level1[5] = g[5] | (p[5] & g[4]);
    assign p_level1[6] = p[6] & p[5];
    assign g_level1[6] = g[6] | (p[6] & g[5]);
    assign p_level1[7] = p[7] & p[6];
    assign g_level1[7] = g[7] | (p[7] & g[6]);

    // Level 2
    assign p_level2[0] = p_level1[0];
    assign g_level2[0] = g_level1[0];
    assign p_level2[1] = p_level1[1];
    assign g_level2[1] = g_level1[1];
    assign p_level2[2] = p_level1[2] & p_level1[0];
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[0]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[4] = p_level1[4] & p_level1[2];
    assign g_level2[4] = g_level1[4] | (p_level1[4] & g_level1[2]);
    assign p_level2[5] = p_level1[5] & p_level1[3];
    assign g_level2[5] = g_level1[5] | (p_level1[5] & g_level1[3]);
    assign p_level2[6] = p_level1[6] & p_level1[4];
    assign g_level2[6] = g_level1[6] | (p_level1[6] & g_level1[4]);
    assign p_level2[7] = p_level1[7] & p_level1[5];
    assign g_level2[7] = g_level1[7] | (p_level1[7] & g_level1[5]);

    // Level 3
    assign p_level3[0] = p_level2[0];
    assign g_level3[0] = g_level2[0];
    assign p_level3[1] = p_level2[1];
    assign g_level3[1] = g_level2[1];
    assign p_level3[2] = p_level2[2];
    assign g_level3[2] = g_level2[2];
    assign p_level3[3] = p_level2[3];
    assign g_level3[3] = g_level2[3];
    assign p_level3[4] = p_level2[4] & p_level2[0];
    assign g_level3[4] = g_level2[4] | (p_level2[4] & g_level2[0]);
    assign p_level3[5] = p_level2[5] & p_level2[1];
    assign g_level3[5] = g_level2[5] | (p_level2[5] & g_level2[1]);
    assign p_level3[6] = p_level2[6] & p_level2[2];
    assign g_level3[6] = g_level2[6] | (p_level2[6] & g_level2[2]);
    assign p_level3[7] = p_level2[7] & p_level2[3];
    assign g_level3[7] = g_level2[7] | (p_level2[7] & g_level2[3]);

    // Generate carry
    assign c[0] = cin;
    assign c[1] = g_level3[0] | (p_level3[0] & cin);
    assign c[2] = g_level3[1] | (p_level3[1] & cin);
    assign c[3] = g_level3[2] | (p_level3[2] & cin);
    assign c[4] = g_level3[3] | (p_level3[3] & cin);
    assign c[5] = g_level3[4] | (p_level3[4] & cin);
    assign c[6] = g_level3[5] | (p_level3[5] & cin);
    assign c[7] = g_level3[6] | (p_level3[6] & cin);
    assign cout_next = g_level3[7] | (p_level3[7] & cin);

    // Generate sum
    assign sum_next = p ^ {c[6:0], cin};

    // Req-Ack handshake logic
    always @(*) begin
        if (req) begin
            sum = sum_next;
            cout = cout_next;
            ack = 1'b1;
        end else begin
            ack = 1'b0;
        end
    end

endmodule

module Multiplier4(
    input [3:0] a, b,
    input req,
    output reg ack,
    output reg [7:0] result
);
    wire [7:0] partial_products [3:0];
    wire [7:0] sum1, sum2;
    wire cout1, cout2;
    wire ack1, ack2, ack3;
    
    // Generate partial products
    assign partial_products[0] = b[0] ? {4'b0, a} : 8'b0;
    assign partial_products[1] = b[1] ? {3'b0, a, 1'b0} : 8'b0;
    assign partial_products[2] = b[2] ? {2'b0, a, 2'b0} : 8'b0;
    assign partial_products[3] = b[3] ? {1'b0, a, 3'b0} : 8'b0;
    
    // First addition stage
    HanCarlsonAdder8 adder1(
        .a(partial_products[0]),
        .b(partial_products[1]),
        .cin(1'b0),
        .req(req),
        .ack(ack1),
        .sum(sum1),
        .cout(cout1)
    );
    
    // Second addition stage
    HanCarlsonAdder8 adder2(
        .a(partial_products[2]),
        .b(partial_products[3]),
        .cin(1'b0),
        .req(req),
        .ack(ack2),
        .sum(sum2),
        .cout(cout2)
    );
    
    // Final addition stage
    HanCarlsonAdder8 adder3(
        .a(sum1),
        .b(sum2),
        .cin(1'b0),
        .req(req),
        .ack(ack3),
        .sum(result),
        .cout()
    );

    // Req-Ack handshake logic
    always @(*) begin
        if (req) begin
            ack = ack1 & ack2 & ack3;
        end else begin
            ack = 1'b0;
        end
    end

endmodule