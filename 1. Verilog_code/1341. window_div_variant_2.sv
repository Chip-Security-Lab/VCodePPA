//SystemVerilog
module window_div #(parameter L=5, H=12) (
    input wire clk, rst_n,
    input wire enable,  // Pipeline enable signal
    output reg clk_out,
    output reg pipeline_valid  // Indicates pipeline output is valid
);
    // Pipeline stage 1: Counter
    reg [7:0] cnt_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Comparison
    reg [7:0] cnt_stage2;
    reg valid_stage2;
    reg comp_result_stage2;
    
    // Stage 1: Counter logic
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end 
        else if (enable) begin
            cnt_stage1 <= cnt_stage1 + 8'd1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Comparison logic
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
            comp_result_stage2 <= 1'b0;
        end 
        else if (enable) begin
            cnt_stage2 <= cnt_stage1;
            valid_stage2 <= valid_stage1;
            comp_result_stage2 <= ((cnt_stage1 >= L) & (cnt_stage1 <= H));
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
            pipeline_valid <= 1'b0;
        end 
        else if (enable) begin
            clk_out <= comp_result_stage2;
            pipeline_valid <= valid_stage2;
        end
    end
endmodule