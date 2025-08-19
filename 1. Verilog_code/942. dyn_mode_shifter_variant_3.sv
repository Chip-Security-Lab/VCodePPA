//SystemVerilog
module dyn_mode_shifter (
    input clk,
    input rst_n,
    // Valid-Ready握手接口
    input [15:0] data_in,
    input [3:0] shift_in,
    input [1:0] mode_in,
    input valid_in,         // 发送方数据有效信号
    output reg ready_out,   // 接收方准备好接收信号
    
    output reg [15:0] data_out,
    output reg valid_out,   // 发送方数据有效信号
    input ready_in          // 接收方准备好接收信号
);

    // 内部寄存器
    reg [15:0] data_reg;
    reg [3:0] shift_reg;
    reg [1:0] mode_reg;
    reg processing;
    
    // 为高扇出信号添加缓冲寄存器
    reg [15:0] data_reg_buf1, data_reg_buf2;
    reg [1:0] mode_reg_buf;
    reg [3:0] shift_reg_buf1, shift_reg_buf2;
    
    // 临时信号，用于计算中间结果
    reg [15:0] shift_left_result;
    reg [15:0] shift_right_result;

    // 缓冲寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_buf1 <= 16'd0;
            data_reg_buf2 <= 16'd0;
            mode_reg_buf <= 2'd0;
            shift_reg_buf1 <= 4'd0;
            shift_reg_buf2 <= 4'd0;
        end else if (processing) begin
            // 更新缓冲寄存器，分散负载
            data_reg_buf1 <= data_reg;
            data_reg_buf2 <= data_reg;
            mode_reg_buf <= mode_reg;
            shift_reg_buf1 <= shift_reg;
            shift_reg_buf2 <= shift_reg;
        end
    end

    // 左移和右移结果的预计算，减少关键路径延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left_result <= 16'd0;
            shift_right_result <= 16'd0;
        end else if (processing) begin
            shift_left_result <= data_reg_buf1 << shift_reg_buf1;
            shift_right_result <= data_reg_buf2 >> (16 - shift_reg_buf2);
        end
    end

    // 控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_out <= 1'b1;  // 复位后准备好接收
            valid_out <= 1'b0;  // 复位后输出无效
            processing <= 1'b0;
            data_out <= 16'd0;
        end else begin
            // 输入握手处理
            if (valid_in && ready_out) begin
                data_reg <= data_in;
                shift_reg <= shift_in;
                mode_reg <= mode_in;
                ready_out <= 1'b0;  // 接收数据后暂时不接收新数据
                processing <= 1'b1;  // 开始处理
            end
            
            // 处理结果 - 使用缓冲后的信号
            if (processing) begin
                case(mode_reg_buf)
                    2'b00: data_out <= shift_left_result;
                    2'b01: data_out <= $signed(data_reg_buf1) >>> shift_reg_buf1;
                    2'b10: data_out <= shift_left_result | shift_right_result;
                    default: data_out <= data_reg_buf1;
                endcase
                valid_out <= 1'b1;  // 结果有效
                processing <= 1'b0;  // 处理完成
            end
            
            // 输出握手处理
            if (valid_out && ready_in) begin
                valid_out <= 1'b0;  // 数据被接收，清除有效标志
                ready_out <= 1'b1;  // 准备接收新数据
            end
        end
    end

endmodule