//SystemVerilog
module odd_divider #(
    parameter N = 5
)(
    input clk,
    input rst,
    output clk_out
);
    // Pipeline stage 1: Counter and phase detection
    reg [2:0] state_stage1;
    reg phase_clk_stage1;
    
    always @(posedge clk or posedge rst) begin
        if (rst) state_stage1 <= 0;
        else if (state_stage1 == N-1) state_stage1 <= 0;
        else state_stage1 <= state_stage1 + 1;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) phase_clk_stage1 <= 0;
        else phase_clk_stage1 <= (state_stage1 < (N>>1)) ? 1'b1 : 1'b0;
    end
    
    // Pipeline stage 2: Negative edge detection
    reg phase_clk_stage2;
    reg phase_clk_neg_stage2;
    
    always @(posedge clk or posedge rst) begin
        if (rst) phase_clk_stage2 <= 0;
        else phase_clk_stage2 <= phase_clk_stage1;
    end
    
    always @(negedge clk) begin
        phase_clk_neg_stage2 <= phase_clk_stage1;
    end
    
    // Pipeline stage 3: Output generation
    reg clk_out_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) clk_out_reg <= 0;
        else clk_out_reg <= phase_clk_stage2 | phase_clk_neg_stage2;
    end
    
    assign clk_out = clk_out_reg;
endmodule