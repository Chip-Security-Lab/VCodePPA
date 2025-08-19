//SystemVerilog
module i2c_multi_reset #(
    parameter RST_SYNC_STAGES = 4  // 增加复位同步阶段数
)(
    input clk_core,
    input clk_io,
    input rst_async,
    output rst_sync,
    inout sda,
    inout scl
);
    // 增加多级流水线复位域管理
    (* ASYNC_REG = "TRUE" *) reg [RST_SYNC_STAGES-1:0] rst_sync_reg;
    (* ASYNC_REG = "TRUE" *) reg rst_sync_stage1, rst_sync_stage2, rst_sync_stage3, rst_sync_stage4;
    wire sda_sync, scl_sync;
    
    // 同步复位生成 - 拆分流水线以减少关键路径
    always @(posedge clk_core or posedge rst_async) begin
        if (rst_async) begin
            rst_sync_reg <= {RST_SYNC_STAGES{1'b1}};
        end else begin
            rst_sync_reg <= {rst_sync_reg[RST_SYNC_STAGES-2:0], 1'b0};
        end
    end

    // 拆分复位处理流水线
    always @(posedge clk_core or posedge rst_async) begin
        if (rst_async) begin
            rst_sync_stage1 <= 1'b1;
        end else begin
            rst_sync_stage1 <= rst_sync_reg[RST_SYNC_STAGES-1];
        end
    end

    // 增加复位信号流水线级数，切割关键路径
    always @(posedge clk_core) begin
        rst_sync_stage2 <= rst_sync_stage1;
        rst_sync_stage3 <= rst_sync_stage2;
        rst_sync_stage4 <= rst_sync_stage3;
    end

    assign rst_sync = rst_sync_stage4;

    // 跨时钟域信号处理 - 拆分流水线减少组合逻辑延迟
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage1;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage2;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage3;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage4;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage5;
    
    // 增加流水线级数，缩短关键路径
    always @(posedge clk_io) begin
        sync_stage1 <= {sda, scl};
        sync_stage2 <= sync_stage1;
    end
    
    always @(posedge clk_io) begin
        sync_stage3 <= sync_stage2;
        sync_stage4 <= sync_stage3;
        sync_stage5 <= sync_stage4;
    end
    
    assign sda_sync = sync_stage5[1];
    assign scl_sync = sync_stage5[0];
    
    // 添加I2C总线驱动逻辑 - 流水线化以减少关键路径
    reg sda_oe_stage1, sda_oe_stage2, sda_oe_stage3, sda_oe;
    reg scl_oe_stage1, scl_oe_stage2, scl_oe_stage3, scl_oe;
    reg sda_out_stage1, sda_out_stage2, sda_out_stage3, sda_out;
    reg scl_out_stage1, scl_out_stage2, scl_out_stage3, scl_out;
    
    // 第一级流水线 - 处理复位和初始逻辑
    always @(posedge clk_io) begin
        if (rst_sync) begin
            sda_oe_stage1 <= 1'b0;
            scl_oe_stage1 <= 1'b0;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= 1'b1;
        end else begin
            // 添加实际控制逻辑的第一级处理
            sda_oe_stage1 <= 1'b0; // 实际逻辑根据需求修改
            scl_oe_stage1 <= 1'b0;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线 - 进行中间处理
    always @(posedge clk_io) begin
        sda_oe_stage2 <= sda_oe_stage1;
        scl_oe_stage2 <= scl_oe_stage1;
        sda_out_stage2 <= sda_out_stage1;
        scl_out_stage2 <= scl_out_stage1;
    end
    
    // 增加第三级流水线 - 减少关键路径延迟
    always @(posedge clk_io) begin
        sda_oe_stage3 <= sda_oe_stage2;
        scl_oe_stage3 <= scl_oe_stage2;
        sda_out_stage3 <= sda_out_stage2;
        scl_out_stage3 <= scl_out_stage2;
    end
    
    // 第四级流水线（输出级）
    always @(posedge clk_io) begin
        sda_oe <= sda_oe_stage3;
        scl_oe <= scl_oe_stage3;
        sda_out <= sda_out_stage3;
        scl_out <= scl_out_stage3;
    end
    
    // 双向引脚控制逻辑 - 将条件判断和输出分配流水线化
    reg sda_tristate, scl_tristate;
    reg sda_out_val, scl_out_val;
    
    // 预计算三态控制条件
    always @(posedge clk_io) begin
        sda_tristate <= sda_oe;
        scl_tristate <= scl_oe;
        sda_out_val <= sda_out;
        scl_out_val <= scl_out;
    end
    
    // 减少组合路径长度
    assign sda = sda_tristate ? sda_out_val : 1'bz;
    assign scl = scl_tristate ? scl_out_val : 1'bz;
endmodule