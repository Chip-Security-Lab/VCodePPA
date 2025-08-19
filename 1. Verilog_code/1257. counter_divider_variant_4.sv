//SystemVerilog
module counter_divider #(parameter RATIO=10) (
    input wire clk, rst,
    output reg clk_out
);
    // Define the counter width using parameter
    localparam CNT_WIDTH = $clog2(RATIO);
    
    // Precompute the target value for comparison
    localparam [CNT_WIDTH-1:0] TARGET = RATIO-1;
    
    // Pipeline stage 1 - Counter
    reg [CNT_WIDTH-1:0] cnt_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Comparison
    reg terminal_count_stage2;
    reg [CNT_WIDTH-1:0] cnt_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 - Update
    reg [CNT_WIDTH-1:0] next_cnt_stage3;
    reg next_clk_out_stage3;
    reg valid_stage3;
    
    // Stage 1: Counter logic
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= {CNT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            cnt_stage1 <= valid_stage3 ? next_cnt_stage3 : cnt_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Comparison logic
    always @(posedge clk) begin
        if (rst) begin
            terminal_count_stage2 <= 1'b0;
            cnt_stage2 <= {CNT_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            terminal_count_stage2 <= (cnt_stage1 == TARGET);
            cnt_stage2 <= cnt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Update counter and output
    always @(posedge clk) begin
        if (rst) begin
            next_cnt_stage3 <= {CNT_WIDTH{1'b0}};
            next_clk_out_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            next_cnt_stage3 <= terminal_count_stage2 ? {CNT_WIDTH{1'b0}} : (cnt_stage2 + 1'b1);
            next_clk_out_stage3 <= terminal_count_stage2 ? ~clk_out : clk_out;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output register
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (valid_stage3) begin
            clk_out <= next_clk_out_stage3;
        end
    end
endmodule