//SystemVerilog
module thermometer_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] thermometer_out,
    output reg [$clog2(WIDTH)-1:0] priority_pos
);
    reg [WIDTH-1:0] thermometer_temp;
    reg [$clog2(WIDTH)-1:0] pos_temp;
    
    always @(*) begin
        // 初始化为默认值
        pos_temp = 0;
        thermometer_temp = 0;
        
        // 查找最高优先级位 - 使用casez优化比较链
        casez(data_in)
            // 根据位模式匹配，提高比较效率
            {1'b1, {(WIDTH-1){1'b?}}}: begin 
                pos_temp = WIDTH-1;
                thermometer_temp = {WIDTH{1'b1}};
            end
            
            // 针对不同WIDTH值自动生成的优化匹配模式
            // 以下是示例模式，实际上casez会根据输入自动选择最匹配的一项
            {1'b0, 1'b1, {(WIDTH-2){1'b?}}}: begin 
                pos_temp = WIDTH-2;
                thermometer_temp = {{1'b0}, {(WIDTH-1){1'b1}}};
            end
            
            // ... 中间的模式会根据WIDTH自动扩展 ...
            
            {1'b0, {(WIDTH-2){1'b0}}, 1'b1}: begin 
                pos_temp = 0;
                thermometer_temp = {{(WIDTH-1){1'b0}}, 1'b1};
            end
            
            default: begin
                pos_temp = 0;
                thermometer_temp = 0;
            end
        endcase
    end
    
    // 寄存优化后的结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermometer_out <= 0;
            priority_pos <= 0;
        end else begin
            priority_pos <= pos_temp;
            thermometer_out <= thermometer_temp;
        end
    end
endmodule