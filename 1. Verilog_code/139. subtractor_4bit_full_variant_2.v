module subtractor_4bit_full (
    input wire clk,
    input wire rst_n,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] diff,
    output reg borrow
);

    // Pipeline stage 1: Input registers and complement generation
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [3:0] b_complement;
    
    // Han-Carlson adder signals
    wire [3:0] p, g;
    wire [3:0] p_stage1, g_stage1;
    wire [3:0] p_stage2, g_stage2;
    wire [3:0] p_stage3, g_stage3;
    wire [3:0] c;
    wire [4:0] sum;
    
    // Stage 1: Register inputs and compute complement
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            b_complement <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            b_complement <= ~b;
        end
    end
    
    // Han-Carlson adder implementation
    // Generate P and G signals
    assign p = a_reg ^ b_complement;
    assign g = a_reg & b_complement;
    
    // Stage 1: Parallel prefix computation
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[2] = p[2] & p[1];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    assign p_stage1[3] = p[3] & p[2];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    
    // Stage 2: Parallel prefix computation
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    
    // Stage 3: Parallel prefix computation
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[2] = g_stage2[2];
    assign p_stage3[3] = p_stage2[3] & p_stage2[1];
    assign g_stage3[3] = g_stage2[3] | (p_stage2[3] & g_stage2[1]);
    
    // Generate carry signals
    assign c[0] = 1'b1; // Initial carry-in for subtraction
    assign c[1] = g_stage3[0];
    assign c[2] = g_stage3[1];
    assign c[3] = g_stage3[2];
    
    // Compute sum
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = g_stage3[3];
    
    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 4'b0;
            borrow <= 1'b0;
        end else begin
            diff <= sum[3:0];
            borrow <= ~sum[4];
        end
    end

endmodule