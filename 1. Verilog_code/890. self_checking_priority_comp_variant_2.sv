//SystemVerilog
// IEEE 1364-2005
module self_checking_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_index,
    output reg valid,
    output reg error
);
    // 第一级流水线寄存器
    reg [WIDTH-1:0] data_in_reg;
    reg has_data_reg;
    
    // 第二级计算和流水线寄存器
    reg [$clog2(WIDTH)-1:0] expected_priority_stage1;
    reg [WIDTH-1:0] priority_mask_stage1;
    reg has_data_stage1;
    
    // 输出级流水线寄存器
    reg [$clog2(WIDTH)-1:0] expected_priority;
    reg [WIDTH-1:0] priority_mask;
    wire has_data = |data_in;
    
    // 优化的优先级编码器
    function automatic [$clog2(WIDTH)-1:0] find_priority;
        input [WIDTH-1:0] data;
        reg [$clog2(WIDTH)-1:0] result;
        begin
            result = 0;
            // 使用条件赋值替代循环以提高性能
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                if (data[i]) result = i[$clog2(WIDTH)-1:0];
            end
            find_priority = result;
        end
    endfunction
    
    // 第一级流水线 - 注册输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
            has_data_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            has_data_reg <= has_data;
        end
    end
    
    // 第二级流水线 - 计算优先级和掩码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_priority_stage1 <= 0;
            priority_mask_stage1 <= 0;
            has_data_stage1 <= 0;
        end else begin
            expected_priority_stage1 <= find_priority(data_in_reg);
            priority_mask_stage1 <= has_data_reg ? (1'b1 << find_priority(data_in_reg)) : 0;
            has_data_stage1 <= has_data_reg;
        end
    end
    
    // 输出级流水线 - 自检并产生最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_index <= 0;
            valid <= 0;
            error <= 0;
            expected_priority <= 0;
            priority_mask <= 0;
        end else begin
            valid <= has_data_stage1;
            expected_priority <= expected_priority_stage1;
            priority_mask <= priority_mask_stage1;
            
            // 赋值输出
            priority_index <= expected_priority_stage1;
            
            // 优化的自检逻辑 - 已被流水线切割
            error <= has_data_stage1 && (data_in_reg & (1'b1 << expected_priority_stage1)) == 0;
        end
    end
endmodule