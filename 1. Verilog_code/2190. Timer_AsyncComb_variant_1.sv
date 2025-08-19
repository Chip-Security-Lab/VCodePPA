//SystemVerilog
module Timer_AsyncComb (
    input clk, rst,
    input [4:0] delay,
    output reg timeout
);
    // Stage 1: Counter
    reg [4:0] cnt_stage1;
    
    // Stage 2: Comparison preparation
    reg [4:0] cnt_stage2;
    reg [4:0] delay_stage2;
    
    // Stage 3: Comparison execution
    reg comparison_result_stage3;
    
    // Counter logic - Stage 1
    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt_stage1 <= 5'b0;
        else
            cnt_stage1 <= cnt_stage1 + 5'b1;
    end
    
    // Register pipeline stage 2
    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt_stage2 <= 5'b0;
        else if (clk)
            cnt_stage2 <= cnt_stage1;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            delay_stage2 <= 5'b0;
        else if (clk)
            delay_stage2 <= delay;
    end
    
    // Comparison logic - Stage 3
    always @(posedge clk or posedge rst) begin
        if (rst)
            comparison_result_stage3 <= 1'b0;
        else if (clk)
            comparison_result_stage3 <= (cnt_stage2 == delay_stage2);
    end
    
    // Output stage
    always @(posedge clk or posedge rst) begin
        if (rst)
            timeout <= 1'b0;
        else if (clk)
            timeout <= comparison_result_stage3;
    end
endmodule