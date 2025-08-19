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
    // 优化复位链路 - 使用参数化移位寄存器
    (* ASYNC_REG = "TRUE" *) reg [RST_SYNC_STAGES-1:0] rst_sync_reg;
    
    // 优化I2C信号同步 - 分离数据通道简化关键路径
    wire sda_sync, scl_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sda_sync_regs;
    (* ASYNC_REG = "TRUE" *) reg [1:0] scl_sync_regs;
    
    // I2C控制信号
    reg sda_oe, scl_oe;
    reg sda_out, scl_out;
    
    // 高扇出信号缓冲寄存器组
    reg rst_sync_buf1, rst_sync_buf2;
    
    // 复位同步电路 - 使用高效移位机制
    always @(posedge clk_core or posedge rst_async) begin
        if (rst_async)
            rst_sync_reg <= {RST_SYNC_STAGES{1'b1}};
        else
            rst_sync_reg <= {rst_sync_reg[RST_SYNC_STAGES-2:0], 1'b0};
    end

    // 直接提取复位信号减少扇出
    assign rst_sync = rst_sync_reg[RST_SYNC_STAGES-1];
    
    // 为高扇出信号rst_sync添加缓冲寄存器
    always @(posedge clk_io) begin
        rst_sync_buf1 <= rst_sync;
        rst_sync_buf2 <= rst_sync;
    end

    // 优化跨时钟域处理 - 分离SDA/SCL同步通道减少干扰
    always @(posedge clk_io) begin
        sda_sync_regs <= {sda_sync_regs[0], sda};
        scl_sync_regs <= {scl_sync_regs[0], scl};
    end
    
    // 平衡后的信号提取
    assign sda_sync = sda_sync_regs[1];
    assign scl_sync = scl_sync_regs[1];
    
    // 优化I2C总线驱动逻辑 - 使用并行结构减少逻辑级数
    always @(posedge clk_io or posedge rst_async) begin
        if (rst_async) begin
            // 异步复位优化减少复位路径延迟
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
        end
        else if (rst_sync_buf1) begin  // 使用缓冲信号降低扇出负载
            // 同步复位路径
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
        end
        // 保留其他控制逻辑位置
    end
    
    // SDA输出寄存器组 - 分散驱动负载
    reg sda_out_buf1, sda_out_buf2;
    reg sda_oe_buf1, sda_oe_buf2;
    
    // SCL输出寄存器组 - 分散驱动负载
    reg scl_out_buf1, scl_out_buf2;
    reg scl_oe_buf1, scl_oe_buf2;
    
    // 高扇出信号缓冲阶段 - 平衡负载
    always @(posedge clk_io or posedge rst_async) begin
        if (rst_async) begin
            sda_out_buf1 <= 1'b1;
            sda_out_buf2 <= 1'b1;
            sda_oe_buf1 <= 1'b0;
            sda_oe_buf2 <= 1'b0;
            
            scl_out_buf1 <= 1'b1;
            scl_out_buf2 <= 1'b1;
            scl_oe_buf1 <= 1'b0;
            scl_oe_buf2 <= 1'b0;
        end
        else if (rst_sync_buf2) begin  // 使用第二个缓冲信号进一步降低扇出负载
            sda_out_buf1 <= 1'b1;
            sda_out_buf2 <= 1'b1;
            sda_oe_buf1 <= 1'b0;
            sda_oe_buf2 <= 1'b0;
            
            scl_out_buf1 <= 1'b1;
            scl_out_buf2 <= 1'b1;
            scl_oe_buf1 <= 1'b0;
            scl_oe_buf2 <= 1'b0;
        end
        else begin
            sda_out_buf1 <= sda_out;
            sda_out_buf2 <= sda_out;
            sda_oe_buf1 <= sda_oe;
            sda_oe_buf2 <= sda_oe;
            
            scl_out_buf1 <= scl_out;
            scl_out_buf2 <= scl_out;
            scl_oe_buf1 <= scl_oe;
            scl_oe_buf2 <= scl_oe;
        end
    end
    
    // 优化三态缓冲控制 - 使用缓冲信号驱动输出逻辑
    assign sda = sda_oe_buf1 ? sda_out_buf1 : 1'bz;
    assign scl = scl_oe_buf1 ? scl_out_buf1 : 1'bz;
    
endmodule