module adder_behavioral (
    input  [3:0] a,
    input  [3:0] b,
    input        clk,       // Clock input for registered operation
    input        rst_n,     // Active-low reset
    output [3:0] sum,
    output       carry
);
    // Stage 1: Generate propagate and generate signals
    reg  [3:0] p_stage1, g_stage1;
    wire [3:0] p_wire, g_wire;
    
    // Basic propagate and generate computation
    assign p_wire = a ^ b;  // Propagate
    assign g_wire = a & b;  // Generate
    
    // Register stage 1 outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_stage1 <= 4'b0;
            g_stage1 <= 4'b0;
        end else begin
            p_stage1 <= p_wire;
            g_stage1 <= g_wire;
        end
    end
    
    // Stage 2: Carry computation - first level
    reg  [1:0] carries_stage2;
    wire [1:0] carries_wire;
    
    // First level carry computation
    assign carries_wire[0] = g_stage1[0];
    assign carries_wire[1] = g_stage1[1] | (p_stage1[1] & g_stage1[0]);
    
    // Register stage 2 outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carries_stage2 <= 2'b0;
        end else begin
            carries_stage2 <= carries_wire;
        end
    end
    
    // Stage 3: Carry computation - second level and sum generation
    reg  [3:0] sum_reg;
    reg        carry_reg;
    wire [4:0] c_wire;
    wire [3:0] sum_wire;
    
    // Complete carry chain computation
    assign c_wire[0] = 1'b0;
    assign c_wire[1] = g_stage1[0];
    assign c_wire[2] = carries_stage2[1];
    assign c_wire[3] = g_stage1[2] | (p_stage1[2] & carries_stage2[1]);
    assign c_wire[4] = g_stage1[3] | (p_stage1[3] & g_stage1[2]) | 
                      (p_stage1[3] & p_stage1[2] & carries_stage2[1]);
    
    // Sum computation
    assign sum_wire = p_stage1 ^ c_wire[3:0];
    
    // Register final outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg   <= 4'b0;
            carry_reg <= 1'b0;
        end else begin
            sum_reg   <= sum_wire;
            carry_reg <= c_wire[4];
        end
    end
    
    // Final outputs
    assign sum   = sum_reg;
    assign carry = carry_reg;
endmodule