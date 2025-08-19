//SystemVerilog
module PredictCompress (
    input clk, en,
    input [15:0] current,
    output reg [7:0] delta
);
    reg [15:0] prev;
    wire [15:0] diff;
    wire [15:0] p, g;
    wire [15:0] carry;
    
    // Generate propagate and generate signals
    assign p = prev ^ 16'hFFFF; // Bitwise invert for subtraction
    assign g = ~prev & 16'hFFFF;
    
    // Parallel prefix carry calculation (Kogge-Stone algorithm)
    // Level 1
    wire [15:0] p_l1, g_l1;
    assign p_l1[0] = p[0];
    assign g_l1[0] = g[0];
    
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : prefix_l1
            assign p_l1[i] = p[i] & p[i-1];
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate
    
    // Level 2
    wire [15:0] p_l2, g_l2;
    assign p_l2[0] = p_l1[0];
    assign p_l2[1] = p_l1[1];
    assign g_l2[0] = g_l1[0];
    assign g_l2[1] = g_l1[1];
    
    generate
        for (i = 2; i < 16; i = i + 1) begin : prefix_l2
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
        end
    endgenerate
    
    // Level 3
    wire [15:0] p_l3, g_l3;
    assign p_l3[0] = p_l2[0];
    assign p_l3[1] = p_l2[1];
    assign p_l3[2] = p_l2[2];
    assign p_l3[3] = p_l2[3];
    assign g_l3[0] = g_l2[0];
    assign g_l3[1] = g_l2[1];
    assign g_l3[2] = g_l2[2];
    assign g_l3[3] = g_l2[3];
    
    generate
        for (i = 4; i < 16; i = i + 1) begin : prefix_l3
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
        end
    endgenerate
    
    // Level 4 (final)
    wire [15:0] p_l4, g_l4;
    assign p_l4[0] = p_l3[0];
    assign p_l4[1] = p_l3[1];
    assign p_l4[2] = p_l3[2];
    assign p_l4[3] = p_l3[3];
    assign p_l4[4] = p_l3[4];
    assign p_l4[5] = p_l3[5];
    assign p_l4[6] = p_l3[6];
    assign p_l4[7] = p_l3[7];
    assign g_l4[0] = g_l3[0];
    assign g_l4[1] = g_l3[1];
    assign g_l4[2] = g_l3[2];
    assign g_l4[3] = g_l3[3];
    assign g_l4[4] = g_l3[4];
    assign g_l4[5] = g_l3[5];
    assign g_l4[6] = g_l3[6];
    assign g_l4[7] = g_l3[7];
    
    generate
        for (i = 8; i < 16; i = i + 1) begin : prefix_l4
            assign p_l4[i] = p_l3[i] & p_l3[i-8];
            assign g_l4[i] = g_l3[i] | (p_l3[i] & g_l3[i-8]);
        end
    endgenerate
    
    // Calculate carry
    assign carry[0] = 1'b1; // Initial carry-in for subtraction
    assign carry[15:1] = g_l4[14:0];
    
    // Calculate difference
    assign diff = current ^ prev ^ carry;
    
    // Register updates
    always @(posedge clk) begin
        if (en) begin
            delta <= diff[7:0];
            prev <= current;
        end
    end
endmodule