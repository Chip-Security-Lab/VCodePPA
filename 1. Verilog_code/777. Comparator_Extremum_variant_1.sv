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
    // 分治比较方法，减少比较路径长度
    
    // 声明临时变量
    reg [WIDTH-1:0] temp_max [0:NUM_INPUTS-1];
    reg [WIDTH-1:0] temp_min [0:NUM_INPUTS-1];
    reg [$clog2(NUM_INPUTS)-1:0] temp_max_idx [0:NUM_INPUTS-1];
    reg [$clog2(NUM_INPUTS)-1:0] temp_min_idx [0:NUM_INPUTS-1];
    
    integer i, j, step;
    
    always @(*) begin
        // 初始化临时数组
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin
            temp_max[i] = data_array[i];
            temp_min[i] = data_array[i];
            temp_max_idx[i] = i[$clog2(NUM_INPUTS)-1:0];
            temp_min_idx[i] = i[$clog2(NUM_INPUTS)-1:0];
        end
        
        // 使用二分法进行比较，减少关键路径
        for (step = 1; step < NUM_INPUTS; step = step * 2) begin
            for (j = 0; j < NUM_INPUTS; j = j + 2*step) begin
                if (j + step < NUM_INPUTS) begin
                    // 比较并更新最大值
                    if (temp_max[j] >= temp_max[j+step]) begin
                        temp_max[j] = temp_max[j];
                        temp_max_idx[j] = temp_max_idx[j];
                    end else begin
                        temp_max[j] = temp_max[j+step];
                        temp_max_idx[j] = temp_max_idx[j+step];
                    end
                    
                    // 比较并更新最小值
                    if (temp_min[j] <= temp_min[j+step]) begin
                        temp_min[j] = temp_min[j];
                        temp_min_idx[j] = temp_min_idx[j];
                    end else begin
                        temp_min[j] = temp_min[j+step];
                        temp_min_idx[j] = temp_min_idx[j+step];
                    end
                end
            end
        end
        
        // 输出结果
        max_val = temp_max[0];
        max_idx = temp_max_idx[0];
        min_val = temp_min[0];
        min_idx = temp_min_idx[0];
    end
endmodule