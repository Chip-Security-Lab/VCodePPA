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
    // 并行比较树结构
    integer i;
    
    always @(*) begin
        max_val = data_array[0];
        min_val = data_array[0];
        max_idx = 0;
        min_idx = 0;
        for (i=1; i<NUM_INPUTS; i=i+1) begin
            if (data_array[i] > max_val) begin
                max_val = data_array[i];
                max_idx = i;
            end
            if (data_array[i] < min_val) begin
                min_val = data_array[i];
                min_idx = i;
            end
        end
    end
endmodule