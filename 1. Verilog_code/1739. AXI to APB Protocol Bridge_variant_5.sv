//SystemVerilog
module axi2apb_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    // AXI-lite接口(简化)
    input [AWIDTH-1:0] axi_awaddr, axi_araddr,
    input [DWIDTH-1:0] axi_wdata,
    input axi_awvalid, axi_wvalid, axi_arvalid, axi_rready, axi_bready,
    output reg [DWIDTH-1:0] axi_rdata,
    output reg axi_awready, axi_wready, axi_arready, axi_rvalid, axi_bvalid,
    // APB接口
    output reg [AWIDTH-1:0] apb_paddr,
    output reg [DWIDTH-1:0] apb_pwdata,
    output reg apb_pwrite, apb_psel, apb_penable,
    input [DWIDTH-1:0] apb_prdata,
    input apb_pready
);
    // 流水线阶段定义
    parameter STAGE_IDLE = 3'b000;
    parameter STAGE_DECODE = 3'b001;
    parameter STAGE_SETUP = 3'b010;
    parameter STAGE_ACCESS = 3'b011;
    parameter STAGE_RESPONSE = 3'b100;
    
    // 流水线寄存器
    reg [2:0] stage1_state, stage2_state, stage3_state;
    reg stage1_valid, stage2_valid, stage3_valid;
    reg stage1_write, stage2_write, stage3_write;
    reg [AWIDTH-1:0] stage1_addr, stage2_addr;
    reg [DWIDTH-1:0] stage1_wdata, stage2_wdata;
    reg [DWIDTH-1:0] stage3_rdata;
    
    // 流水线控制信号
    reg pipeline_busy;
    reg read_transaction_active;
    reg write_transaction_active;
    
    // 请求握手处理 - 阶段1 (解码和接收请求)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_state <= STAGE_IDLE;
            stage1_valid <= 1'b0;
            stage1_write <= 1'b0;
            stage1_addr <= {AWIDTH{1'b0}};
            stage1_wdata <= {DWIDTH{1'b0}};
            axi_awready <= 1'b1;
            axi_wready <= 1'b1;
            axi_arready <= 1'b1;
            read_transaction_active <= 1'b0;
            write_transaction_active <= 1'b0;
        end else begin
            // 默认保持当前状态
            stage1_valid <= 1'b0;
            
            // 写请求优先级高于读请求
            if (axi_awvalid && axi_wvalid && !write_transaction_active && !read_transaction_active && axi_awready && axi_wready) begin
                // 接收写请求
                stage1_state <= STAGE_DECODE;
                stage1_valid <= 1'b1;
                stage1_write <= 1'b1;
                stage1_addr <= axi_awaddr;
                stage1_wdata <= axi_wdata;
                axi_awready <= 1'b0;
                axi_wready <= 1'b0;
                write_transaction_active <= 1'b1;
            end else if (axi_arvalid && !read_transaction_active && !write_transaction_active && axi_arready) begin
                // 接收读请求
                stage1_state <= STAGE_DECODE;
                stage1_valid <= 1'b1;
                stage1_write <= 1'b0;
                stage1_addr <= axi_araddr;
                axi_arready <= 1'b0;
                read_transaction_active <= 1'b1;
            end
            
            // 当事务完成时重置活动标志
            if (axi_bvalid && axi_bready) begin
                write_transaction_active <= 1'b0;
                axi_awready <= 1'b1;
                axi_wready <= 1'b1;
            end
            
            if (axi_rvalid && axi_rready) begin
                read_transaction_active <= 1'b0;
                axi_arready <= 1'b1;
            end
        end
    end
    
    // 流水线阶段2 (APB设置阶段)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_state <= STAGE_IDLE;
            stage2_valid <= 1'b0;
            stage2_write <= 1'b0;
            stage2_addr <= {AWIDTH{1'b0}};
            stage2_wdata <= {DWIDTH{1'b0}};
            apb_psel <= 1'b0;
            apb_penable <= 1'b0;
            apb_paddr <= {AWIDTH{1'b0}};
            apb_pwdata <= {DWIDTH{1'b0}};
            apb_pwrite <= 1'b0;
        end else begin
            stage2_valid <= 1'b0;
            
            if (stage1_valid) begin
                // 从阶段1传递到阶段2
                stage2_state <= STAGE_SETUP;
                stage2_valid <= 1'b1;
                stage2_write <= stage1_write;
                stage2_addr <= stage1_addr;
                stage2_wdata <= stage1_wdata;
                
                // 设置APB信号 - SETUP阶段
                apb_psel <= 1'b1;
                apb_paddr <= stage1_addr;
                apb_pwrite <= stage1_write;
                if (stage1_write) begin
                    apb_pwdata <= stage1_wdata;
                end
            end else if (stage2_valid && stage2_state == STAGE_SETUP) begin
                // 进入到ACCESS阶段
                stage2_state <= STAGE_ACCESS;
                apb_penable <= 1'b1;
            end else if (stage2_state == STAGE_ACCESS && apb_pready) begin
                // 完成访问
                stage2_valid <= 1'b1;
                stage2_state <= STAGE_RESPONSE;
                apb_psel <= 1'b0;
                apb_penable <= 1'b0;
            end
        end
    end
    
    // 流水线阶段3 (响应处理)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_state <= STAGE_IDLE;
            stage3_valid <= 1'b0;
            stage3_write <= 1'b0;
            stage3_rdata <= {DWIDTH{1'b0}};
            axi_bvalid <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rdata <= {DWIDTH{1'b0}};
        end else begin
            if (stage2_valid && stage2_state == STAGE_RESPONSE) begin
                stage3_state <= STAGE_RESPONSE;
                stage3_valid <= 1'b1;
                stage3_write <= stage2_write;
                
                if (!stage2_write) begin
                    // 捕获读数据
                    stage3_rdata <= apb_prdata;
                    axi_rdata <= apb_prdata;
                    axi_rvalid <= 1'b1;
                end else begin
                    // 写响应
                    axi_bvalid <= 1'b1;
                end
            end
            
            // 清除响应标志
            if (axi_bvalid && axi_bready) begin
                axi_bvalid <= 1'b0;
                stage3_valid <= 1'b0;
            end
            
            if (axi_rvalid && axi_rready) begin
                axi_rvalid <= 1'b0;
                stage3_valid <= 1'b0;
            end
        end
    end
    
    // 忙碌状态管理 - 防止流水线冲突
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_busy <= 1'b0;
        end else begin
            if (stage1_valid || stage2_valid || stage3_valid) begin
                pipeline_busy <= 1'b1;
            end else if (!stage1_valid && !stage2_valid && !stage3_valid) begin
                pipeline_busy <= 1'b0;
            end
        end
    end
    
endmodule