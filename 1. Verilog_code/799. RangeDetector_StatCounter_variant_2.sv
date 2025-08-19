//SystemVerilog
module RangeDetector_StatCounter #(
    parameter WIDTH = 8,
    parameter CNT_WIDTH = 16
)(
    input clk, rst_n, clear,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] min_val,
    input [WIDTH-1:0] max_val,
    input data_valid,
    output reg [CNT_WIDTH-1:0] valid_count,
    output reg result_valid
);
    // Pipeline stage 1 - Range comparison
    reg [WIDTH-1:0] data_stage1, min_val_stage1, max_val_stage1;
    reg in_range_stage1;
    reg valid_stage1;
    reg clear_stage1;
    
    // Pipeline stage 2 - Counter management
    reg in_range_stage2;
    reg valid_stage2;
    reg clear_stage2;
    
    // Stage 1: Range detection
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_stage1 <= 0;
            min_val_stage1 <= 0;
            max_val_stage1 <= 0;
            in_range_stage1 <= 0;
            valid_stage1 <= 0;
            clear_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            min_val_stage1 <= min_val;
            max_val_stage1 <= max_val;
            in_range_stage1 <= (data_in >= min_val) && (data_in <= max_val);
            valid_stage1 <= data_valid;
            clear_stage1 <= clear;
        end
    end
    
    // Stage 2: Counter control signals
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            in_range_stage2 <= 0;
            valid_stage2 <= 0;
            clear_stage2 <= 0;
        end else begin
            in_range_stage2 <= in_range_stage1;
            valid_stage2 <= valid_stage1;
            clear_stage2 <= clear_stage1;
        end
    end
    
    // Final stage: Counter update
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_count <= 0;
            result_valid <= 0;
        end else if(clear_stage2) begin
            valid_count <= 0;
            result_valid <= valid_stage2;
        end else if(valid_stage2 && in_range_stage2) begin
            valid_count <= valid_count + 1;
            result_valid <= 1;
        end else begin
            result_valid <= valid_stage2;
        end
    end
endmodule