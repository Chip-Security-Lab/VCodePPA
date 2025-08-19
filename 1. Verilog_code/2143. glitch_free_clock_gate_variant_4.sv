//SystemVerilog
module glitch_free_clock_gate (
    // Clock and reset signals
    input  wire        clk_in,
    input  wire        rst_n,
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,  // 替代原来的enable信号
    input  wire [0:0]  s_axis_tdata,   // 数据位宽为1bit
    output wire        s_axis_tready,  // 新增的ready信号
    
    // Clock output
    output wire        clk_out
);
    // 内部信号定义
    reg enable_stage1, enable_stage2, enable_stage3, enable_stage4;
    reg s_axis_tready_reg;
    wire enable;
    
    // TDATA包含enable信号
    assign enable = s_axis_tvalid & s_axis_tdata[0];
    
    // 始终准备接收数据
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready_reg <= 1'b0;
        end else begin
            s_axis_tready_reg <= 1'b1;  // 永远准备接收新的控制信号
        end
    end
    
    assign s_axis_tready = s_axis_tready_reg;
    
    // 流水线第一阶段 - 应用AXI-Stream握手机制
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            enable_stage1 <= s_axis_tdata[0];  // 只在握手成功时更新
        end
    end
    
    // 流水线第二阶段
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
        end else begin
            enable_stage2 <= enable_stage1;
        end
    end
    
    // 流水线第三阶段
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage3 <= 1'b0;
        end else begin
            enable_stage3 <= enable_stage2;
        end
    end
    
    // 流水线第四阶段
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage4 <= 1'b0;
        end else begin
            enable_stage4 <= enable_stage3;
        end
    end
    
    // 时钟门控输出 - 功能保持不变
    assign clk_out = clk_in & enable_stage4;
    
endmodule