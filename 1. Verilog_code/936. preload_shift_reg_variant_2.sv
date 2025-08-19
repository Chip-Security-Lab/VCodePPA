//SystemVerilog
module preload_shift_reg (
    input clk,
    input rst_n,        // 添加复位信号
    input load,
    input data_valid,   // 输入数据有效信号
    output reg ready,   // 准备好接收数据信号
    input [3:0] shift,
    input [15:0] load_data,
    output reg [15:0] shifted,
    output reg shifted_valid  // 输出数据有效信号
);
    // 流水线寄存器
    reg [15:0] storage_stage1;
    reg [15:0] data_stage1, data_stage2;
    reg [3:0] shift_stage1, shift_stage2;
    reg valid_stage1, valid_stage2;
    reg load_stage1;
    
    // 临时信号用于桶形移位器
    wire [15:0] barrel_shift_out;
    
    // 流水线阶段1：数据加载与存储
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            storage_stage1 <= 16'b0;
            data_stage1 <= 16'b0;
            shift_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
            load_stage1 <= 1'b0;
            ready <= 1'b1;
        end else begin
            if (ready && data_valid) begin
                // 输入数据寄存
                data_stage1 <= load_data;
                shift_stage1 <= shift;
                valid_stage1 <= 1'b1;
                load_stage1 <= load;
                
                // 更新存储值
                if (load) storage_stage1 <= load_data;
            end else if (valid_stage1) begin
                valid_stage1 <= 1'b0;
            end
            
            // 控制流水线背压
            if (valid_stage2) ready <= 1'b0;
            else ready <= 1'b1;
        end
    end
    
    // 桶形移位器实现
    // 第一级：移动0或1位
    wire [15:0] level1_out;
    assign level1_out = shift_stage1[0] ? {storage_stage1[14:0], storage_stage1[15]} : storage_stage1;
    
    // 第二级：移动0或2位
    wire [15:0] level2_out;
    assign level2_out = shift_stage1[1] ? {level1_out[13:0], level1_out[15:14]} : level1_out;
    
    // 第三级：移动0或4位
    wire [15:0] level3_out;
    assign level3_out = shift_stage1[2] ? {level2_out[11:0], level2_out[15:12]} : level2_out;
    
    // 第四级：移动0或8位
    wire [15:0] level4_out;
    assign level4_out = shift_stage1[3] ? {level3_out[7:0], level3_out[15:8]} : level3_out;
    
    // 输出桶形移位器结果
    assign barrel_shift_out = level4_out;
    
    // 流水线阶段2：执行移位计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 16'b0;
            shift_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 当前阶段接收上一阶段的数据和控制信号
            shift_stage2 <= shift_stage1;
            valid_stage2 <= valid_stage1;
            
            // 使用桶形移位器结果
            if (!load_stage1)
                data_stage2 <= barrel_shift_out;
            else
                data_stage2 <= 16'b0;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 流水线阶段3：输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted <= 16'b0;
            shifted_valid <= 1'b0;
        end else begin
            shifted_valid <= valid_stage2;
            if (valid_stage2) shifted <= data_stage2;
        end
    end
    
endmodule