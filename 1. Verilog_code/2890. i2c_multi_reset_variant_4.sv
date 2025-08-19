//SystemVerilog
module i2c_multi_reset #(
    parameter RST_SYNC_STAGES = 2
)(
    input clk_core,
    input clk_io,
    input rst_async,
    output rst_sync,
    inout sda,
    inout scl
);
    // 多复位域管理
    (* ASYNC_REG = "TRUE" *) reg [RST_SYNC_STAGES-1:0] rst_sync_reg;
    wire sda_in, scl_in;
    wire sda_sync, scl_sync;
    
    // 捕获输入信号 - 前向重定时
    assign sda_in = sda;
    assign scl_in = scl;
    
    // 同步复位生成 - 保持对rst_async的敏感度
    always @(posedge clk_core or posedge rst_async) begin
        if (rst_async) begin
            rst_sync_reg <= {RST_SYNC_STAGES{1'b1}};
        end else begin
            rst_sync_reg <= {rst_sync_reg[RST_SYNC_STAGES-2:0], 1'b0};
        end
    end

    assign rst_sync = rst_sync_reg[RST_SYNC_STAGES-1];

    // 跨时钟域信号处理 - 流水线优化
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_data;      // 组合逻辑后的寄存器
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage2;    // 保持第二级寄存器
    
    // 注意：将第一级寄存器直接接收处理后的输入
    always @(posedge clk_io) begin
        sync_data <= {sda_in, scl_in};         // 前向重定时：直接连接到输入信号
        sync_stage2 <= sync_data;              // 第二级同步
    end
    
    assign sda_sync = sync_stage2[1];
    assign scl_sync = sync_stage2[0];
    
    // I2C总线驱动逻辑 - 引入流水线寄存器切分关键路径
    reg sda_oe_pre, scl_oe_pre;       // 中间流水线寄存器
    reg sda_oe, scl_oe;               // 输出寄存器
    reg sda_out, scl_out;
    
    // 第一级流水线: 计算输出使能前值
    always @(posedge clk_io) begin
        if (rst_sync) begin
            sda_oe_pre <= 1'b0;
            scl_oe_pre <= 1'b0;
        end else begin
            // 拆分组合逻辑，减少关键路径
            sda_oe_pre <= ~sda_sync;  // 计算但不直接输出
            scl_oe_pre <= ~scl_sync;
        end
    end
    
    // 第二级流水线: 最终输出控制
    always @(posedge clk_io) begin
        if (rst_sync) begin
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
        end else begin
            // 使用预计算的值
            sda_oe <= sda_oe_pre;     // 将计算拆分为两个周期
            scl_oe <= scl_oe_pre;
            
            // 维持总线默认电平
            sda_out <= 1'b1;
            scl_out <= 1'b1;
        end
    end
    
    // 三态输出驱动 - 保持不变
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
endmodule