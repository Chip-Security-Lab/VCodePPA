//SystemVerilog
module Comparator_Extremum #(
    parameter WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  [NUM_INPUTS-1:0][WIDTH-1:0] data_array,
    output reg [WIDTH-1:0]             max_val,
    output reg [$clog2(NUM_INPUTS)-1:0] max_idx,
    output reg [WIDTH-1:0]             min_val,
    output reg [$clog2(NUM_INPUTS)-1:0] min_idx 
);

    // 使用分治法优化比较树
    genvar i;
    generate
        if (NUM_INPUTS == 1) begin
            always @(*) begin
                max_val = data_array[0];
                min_val = data_array[0];
                max_idx = 0;
                min_idx = 0;
            end
        end else begin
            // 将输入分成两半进行比较
            localparam HALF = NUM_INPUTS/2;
            wire [WIDTH-1:0] max_val_l, max_val_r;
            wire [WIDTH-1:0] min_val_l, min_val_r;
            wire [$clog2(HALF)-1:0] max_idx_l, max_idx_r;
            wire [$clog2(HALF)-1:0] min_idx_l, min_idx_r;
            
            // 左半部分比较
            Comparator_Extremum #(
                .WIDTH(WIDTH),
                .NUM_INPUTS(HALF)
            ) left_comp (
                .data_array(data_array[HALF-1:0]),
                .max_val(max_val_l),
                .max_idx(max_idx_l),
                .min_val(min_val_l),
                .min_idx(min_idx_l)
            );
            
            // 右半部分比较
            Comparator_Extremum #(
                .WIDTH(WIDTH),
                .NUM_INPUTS(NUM_INPUTS-HALF)
            ) right_comp (
                .data_array(data_array[NUM_INPUTS-1:HALF]),
                .max_val(max_val_r),
                .max_idx(max_idx_r),
                .min_val(min_val_r),
                .min_idx(min_idx_r)
            );
            
            // 合并结果
            always @(*) begin
                if (max_val_l > max_val_r) begin
                    max_val = max_val_l;
                    max_idx = max_idx_l;
                end else begin
                    max_val = max_val_r;
                    max_idx = max_idx_r + HALF;
                end
                
                if (min_val_l < min_val_r) begin
                    min_val = min_val_l;
                    min_idx = min_idx_l;
                end else begin
                    min_val = min_val_r;
                    min_idx = min_idx_r + HALF;
                end
            end
        end
    endgenerate
endmodule