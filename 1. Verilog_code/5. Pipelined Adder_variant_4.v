module pipelined_adder (
    input clk,
    input [3:0] a, b,
    output reg [3:0] sum
);

    // Stage 1 registers
    reg [3:0] stage1_a, stage1_b;
    
    // Stage 2 registers
    reg [3:0] stage2_a, stage2_b;
    
    // Stage 3 registers
    reg [3:0] stage3_a, stage3_b;
    
    // Stage 4 Brent-Kung signals
    reg [3:0] stage4_p, stage4_g;
    
    // Stage 5 carry computation
    reg [3:0] stage5_c;
    
    // Stage 6 sum computation
    reg [3:0] stage6_sum;
    
    // Stage 1: Input registers
    always @(posedge clk) begin
        stage1_a <= a;
        stage1_b <= b;
    end
    
    // Stage 2: Intermediate registers
    always @(posedge clk) begin
        stage2_a <= stage1_a;
        stage2_b <= stage1_b;
    end
    
    // Stage 3: Additional pipeline stage
    always @(posedge clk) begin
        stage3_a <= stage2_a;
        stage3_b <= stage2_b;
    end
    
    // Stage 4: Generate P and G signals
    always @(posedge clk) begin
        stage4_p <= stage3_a ^ stage3_b;
        stage4_g <= stage3_a & stage3_b;
    end
    
    // Stage 5: Brent-Kung carry computation
    always @(posedge clk) begin
        stage5_c[0] <= stage4_g[0];
        stage5_c[1] <= stage4_g[1] | (stage4_p[1] & stage4_g[0]);
        stage5_c[2] <= stage4_g[2] | (stage4_p[2] & stage4_g[1]) | (stage4_p[2] & stage4_p[1] & stage4_g[0]);
        stage5_c[3] <= stage4_g[3] | (stage4_p[3] & stage4_g[2]) | (stage4_p[3] & stage4_p[2] & stage4_g[1]) | 
                      (stage4_p[3] & stage4_p[2] & stage4_p[1] & stage4_g[0]);
    end
    
    // Stage 6: Final sum computation
    always @(posedge clk) begin
        stage6_sum <= stage4_p ^ {stage5_c[2:0], 1'b0};
    end
    
    // Output register
    always @(posedge clk) begin
        sum <= stage6_sum;
    end

endmodule