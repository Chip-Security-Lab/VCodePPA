//SystemVerilog
module crossbar_async_4x4 (
    input  wire [7:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input  wire [1:0] select_out_0, select_out_1, select_out_2, select_out_3,
    output wire [7:0] data_out_0, data_out_1, data_out_2, data_out_3,
    input  wire       clk
);

    // 定义输入和选择信号寄存器
    reg [7:0] data_in_reg_0, data_in_reg_1, data_in_reg_2, data_in_reg_3;
    reg [1:0] select_reg_0, select_reg_1, select_reg_2, select_reg_3;
    
    // 定义流水线中间结果寄存器
    reg [7:0] data_out_stage1_0, data_out_stage1_1, data_out_stage1_2, data_out_stage1_3;
    reg [7:0] data_out_stage2_0, data_out_stage2_1, data_out_stage2_2, data_out_stage2_3;
    
    // 输入数据寄存 - 第一级流水线
    always @(posedge clk) begin
        data_in_reg_0 <= data_in_0;
        data_in_reg_1 <= data_in_1;
        data_in_reg_2 <= data_in_2;
        data_in_reg_3 <= data_in_3;
    end
    
    // 选择信号寄存 - 第一级流水线
    always @(posedge clk) begin
        select_reg_0 <= select_out_0;
        select_reg_1 <= select_out_1;
        select_reg_2 <= select_out_2;
        select_reg_3 <= select_out_3;
    end
    
    // 第一输出通道选择 - 第二级流水线
    always @(posedge clk) begin
        case(select_reg_0)
            2'b00: data_out_stage1_0 <= data_in_reg_0;
            2'b01: data_out_stage1_0 <= data_in_reg_1;
            2'b10: data_out_stage1_0 <= data_in_reg_2;
            2'b11: data_out_stage1_0 <= data_in_reg_3;
        endcase
    end
    
    // 第二输出通道选择 - 第二级流水线
    always @(posedge clk) begin
        case(select_reg_1)
            2'b00: data_out_stage1_1 <= data_in_reg_0;
            2'b01: data_out_stage1_1 <= data_in_reg_1;
            2'b10: data_out_stage1_1 <= data_in_reg_2;
            2'b11: data_out_stage1_1 <= data_in_reg_3;
        endcase
    end
    
    // 第三输出通道选择 - 第二级流水线
    always @(posedge clk) begin
        case(select_reg_2)
            2'b00: data_out_stage1_2 <= data_in_reg_0;
            2'b01: data_out_stage1_2 <= data_in_reg_1;
            2'b10: data_out_stage1_2 <= data_in_reg_2;
            2'b11: data_out_stage1_2 <= data_in_reg_3;
        endcase
    end
    
    // 第四输出通道选择 - 第二级流水线
    always @(posedge clk) begin
        case(select_reg_3)
            2'b00: data_out_stage1_3 <= data_in_reg_0;
            2'b01: data_out_stage1_3 <= data_in_reg_1;
            2'b10: data_out_stage1_3 <= data_in_reg_2;
            2'b11: data_out_stage1_3 <= data_in_reg_3;
        endcase
    end
    
    // 输出寄存 - 第三级流水线（分开实现，便于时序优化）
    always @(posedge clk) begin
        data_out_stage2_0 <= data_out_stage1_0;
    end
    
    always @(posedge clk) begin
        data_out_stage2_1 <= data_out_stage1_1;
    end
    
    always @(posedge clk) begin
        data_out_stage2_2 <= data_out_stage1_2;
    end
    
    always @(posedge clk) begin
        data_out_stage2_3 <= data_out_stage1_3;
    end
    
    // 将寄存器输出连接到模块输出端口
    assign data_out_0 = data_out_stage2_0;
    assign data_out_1 = data_out_stage2_1;
    assign data_out_2 = data_out_stage2_2;
    assign data_out_3 = data_out_stage2_3;

endmodule