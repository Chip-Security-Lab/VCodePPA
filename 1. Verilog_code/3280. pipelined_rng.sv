module pipelined_rng (
    input wire clk,
    input wire rst_n,
    output wire [31:0] random_data
);
    reg [31:0] stage1_reg, stage2_reg, stage3_reg;
    wire [31:0] stage1_next, stage2_next, stage3_next;
    
    // Stage 1: LFSR
    assign stage1_next = {stage1_reg[30:0], stage1_reg[31] ^ stage1_reg[28] ^ 
                         stage1_reg[15] ^ stage1_reg[0]};
    
    // Stage 2: Bit shuffle
    assign stage2_next = {stage1_reg[15:0], stage1_reg[31:16]} ^ 
                         {stage2_reg[7:0], stage2_reg[31:8]};
    
    // Stage 3: Nonlinear transformation
    assign stage3_next = stage2_reg + (stage3_reg ^ (stage3_reg << 5));
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= 32'h12345678;
            stage2_reg <= 32'h87654321;
            stage3_reg <= 32'hABCDEF01;
        end else begin
            stage1_reg <= stage1_next;
            stage2_reg <= stage2_next;
            stage3_reg <= stage3_next;
        end
    end
    
    assign random_data = stage3_reg;
endmodule