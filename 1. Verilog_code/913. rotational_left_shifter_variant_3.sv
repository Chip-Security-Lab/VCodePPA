//SystemVerilog
module rotational_left_shifter (
    input clock,
    input reset,
    input valid,               // 替换enable，表示输入数据有效
    output reg ready,          // 新增输出信号，表示模块准备好接收数据
    input [15:0] data_input,
    input [3:0] rotate_amount,
    output reg [15:0] data_output,
    output reg data_output_valid // 新增输出信号，表示输出数据有效
);
    // 内部状态定义
    reg processing;
    reg [15:0] rotated_data_reg;
    
    // 旋转计算逻辑
    wire [15:0] rotated_data;
    assign rotated_data = (data_input << rotate_amount) | (data_input >> (16 - rotate_amount));
    
    // 握手控制和数据处理
    always @(posedge clock) begin
        if (reset) begin
            data_output <= 16'd0;
            data_output_valid <= 1'b0;
            ready <= 1'b1;         // 复位后准备接收新数据
            processing <= 1'b0;
            rotated_data_reg <= 16'd0;
        end else begin
            // 握手逻辑
            if (valid && ready) begin
                // 有效数据到达，且模块准备好接收
                rotated_data_reg <= rotated_data;
                processing <= 1'b1;
                ready <= 1'b0;     // 不再接收新数据
                data_output_valid <= 1'b0; // 确保数据处理过程中输出无效
            end
            
            // 处理完成逻辑
            if (processing) begin
                data_output <= rotated_data_reg;
                data_output_valid <= 1'b1;  // 输出数据有效
                processing <= 1'b0;
                ready <= 1'b1;              // 准备接收下一个数据
            end else if (data_output_valid && !processing) begin
                // 数据已输出，等待下一个周期
                data_output_valid <= 1'b0;  // 只保持一个周期的有效信号
            end
        end
    end
endmodule