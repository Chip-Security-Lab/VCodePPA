//SystemVerilog
module pl_reg_async_comb #(
    parameter W = 8
) (
    input wire clk,
    input wire arst,
    input wire load,
    input wire [W-1:0] din,
    output wire [W-1:0] dout
);
    reg [W-1:0] reg_d;
    wire [W-1:0] subtractor_result;
    wire [W:0] borrow; // extra bit for initial borrow
    wire [W-1:0] operand_a, operand_b;
    
    // Parallel prefix subtractor implementation
    // Generate propagate and generate signals for each bit
    wire [W-1:0] p, g;
    
    // Input to subtractor
    assign operand_a = reg_d;
    assign operand_b = 8'b00000001; // Subtract 1 as an example operation
    
    // Generate propagate (p) and generate (g) signals
    // In subtraction: p_i = a_i XOR b_i, g_i = NOT(a_i) AND b_i
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_pg_signals
            assign p[i] = operand_a[i] ^ operand_b[i];
            assign g[i] = ~operand_a[i] & operand_b[i];
        end
    endgenerate
    
    // Parallel prefix network for borrow computation (Kogge-Stone algorithm)
    // Level 1
    wire [W-1:0] p_l1, g_l1;
    
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_level1
            if (i == 0) begin
                assign p_l1[i] = p[i];
                assign g_l1[i] = g[i];
            end else begin
                assign p_l1[i] = p[i] & p[i-1];
                assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            end
        end
    endgenerate
    
    // Level 2
    wire [W-1:0] p_l2, g_l2;
    
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_level2
            if (i < 2) begin
                assign p_l2[i] = p_l1[i];
                assign g_l2[i] = g_l1[i];
            end else begin
                assign p_l2[i] = p_l1[i] & p_l1[i-2];
                assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            end
        end
    endgenerate
    
    // Level 3
    wire [W-1:0] p_l3, g_l3;
    
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_level3
            if (i < 4) begin
                assign p_l3[i] = p_l2[i];
                assign g_l3[i] = g_l2[i];
            end else begin
                assign p_l3[i] = p_l2[i] & p_l2[i-4];
                assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            end
        end
    endgenerate
    
    // Compute final borrow
    assign borrow[0] = 1'b0; // Initial borrow is 0
    
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_borrow
            if (i == 0)
                assign borrow[i+1] = g_l3[i];
            else
                assign borrow[i+1] = g_l3[i];
        end
    endgenerate
    
    // Compute the difference
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_difference
            assign subtractor_result[i] = p[i] ^ borrow[i];
        end
    endgenerate
    
    // Register logic with async reset
    always @(posedge clk or posedge arst) begin
        if (arst)
            reg_d <= {W{1'b0}};
        else if (load)
            reg_d <= din;
        else
            reg_d <= subtractor_result; // Use the subtractor result when not loading
    end
    
    assign dout = reg_d;
    
endmodule