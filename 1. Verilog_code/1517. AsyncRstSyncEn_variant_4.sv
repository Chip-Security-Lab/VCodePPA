//SystemVerilog
// IEEE 1364-2005 Verilog standard
module AsyncRstSyncEn #(
    parameter W = 6
)(
    input  wire        sys_clk,
    input  wire        async_rst_n,
    input  wire        en_shift,
    input  wire        serial_data,
    output reg  [W-1:0] shift_reg,
    // Pipeline control signals
    input  wire        valid_in,
    output wire        valid_out,
    input  wire        ready_in,
    output wire        ready_out
);

    // ===== 数据流阶段定义 =====
    // 第一级流水线数据和控制信号
    reg  [W-1:0] data_stage1;
    reg          valid_stage1;
    wire         ready_stage1;
    
    // 第二级流水线数据和控制信号
    reg  [W-1:0] data_stage2;
    reg          valid_stage2;
    wire         ready_stage2;
    
    // ===== 数据路径逻辑 =====
    // 输入数据组合逻辑 - 决定下一个移位寄存器值
    wire [W-1:0] next_shift_data;
    assign next_shift_data = en_shift ? {shift_reg[W-2:0], serial_data} : shift_reg;
    
    // ===== 反向压力控制逻辑 =====
    // 从下游到上游的反向压力传播
    assign ready_stage2 = ready_in || !valid_stage2;  // 第二级就绪条件
    assign ready_stage1 = ready_stage2 || !valid_stage1;  // 第一级就绪条件
    assign ready_out = ready_stage1;                  // 向上游提供就绪信号
    
    // ===== 正向有效信号传播 =====
    // 输出有效信号
    assign valid_out = valid_stage2;
    
    // ===== 第一级流水线 =====
    // 数据捕获和初始处理
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // 异步复位
            data_stage1 <= {W{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else if (ready_stage1) begin
            // 当第一级可接收数据时
            if (valid_in) begin
                // 捕获输入数据并更新有效标志
                data_stage1 <= next_shift_data;
                valid_stage1 <= 1'b1;
            end
            else begin
                // 无效输入时，仅清除有效标志
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // ===== 第二级流水线 =====
    // 数据处理和输出准备
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // 异步复位
            data_stage2 <= {W{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (ready_stage2) begin
            // 当第二级可接收数据时
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // ===== 输出寄存器更新 =====
    // 最终数据输出
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // 异步复位
            shift_reg <= {W{1'b0}};
        end
        else if (valid_stage2 && ready_in) begin
            // 只有当第二级数据有效且下游准备好接收时更新输出
            shift_reg <= data_stage2;
        end
    end

endmodule