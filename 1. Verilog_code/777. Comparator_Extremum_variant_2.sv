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
    // 条件反相减法器算法实现
    integer i;
    reg [WIDTH-1:0] inverted_data;
    reg [WIDTH-1:0] diff;
    reg is_greater;
    reg is_less;
    
    always @(*) begin
        max_val = data_array[0];
        min_val = data_array[0];
        max_idx = 0;
        min_idx = 0;
        
        for (i=1; i<NUM_INPUTS; i=i+1) begin
            // 条件反相减法器算法 - 最大值比较
            inverted_data = ~data_array[i] + 1'b1; // 取反加1得到补码
            diff = max_val + inverted_data;        // 减法操作
            is_greater = ~diff[WIDTH-1];           // 如果结果为正，则data_array[i] > max_val
            
            if (is_greater) begin
                max_val = data_array[i];
                max_idx = i;
            end
            
            // 条件反相减法器算法 - 最小值比较
            inverted_data = ~min_val + 1'b1;       // 取反加1得到补码
            diff = data_array[i] + inverted_data;  // 减法操作
            is_less = ~diff[WIDTH-1];              // 如果结果为正，则data_array[i] < min_val
            
            if (is_less) begin
                min_val = data_array[i];
                min_idx = i;
            end
        end
    end
endmodule