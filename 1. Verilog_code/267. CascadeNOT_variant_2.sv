//SystemVerilog
module CascadeNOT(
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 低电平有效复位信号
    // AXI-Stream 输入接口
    input  wire [3:0]  s_axis_tdata, // 输入数据
    input  wire        s_axis_tvalid, // 输入数据有效
    output wire        s_axis_tready, // 准备接收输入
    // AXI-Stream 输出接口
    output wire [3:0]  m_axis_tdata, // 输出数据
    output wire        m_axis_tvalid, // 输出数据有效
    input  wire        m_axis_tready  // 下游准备接收
);
    // 内部流水线寄存器和组合逻辑信号
    reg  [3:0] bits_stage1;
    reg  [3:0] inv_stage1;
    reg  [3:0] inv_stage2;
    
    // 第一级取反的组合逻辑 - 提前计算，不再在寄存器中
    wire [3:0] inv_comb1;
    assign inv_comb1 = ~s_axis_tdata;  // 将组合逻辑移到寄存器前面
    
    // 第二级取反的组合逻辑
    wire [3:0] inv_comb2;
    assign inv_comb2 = inv_stage1;
    
    // 流控信号
    reg stage1_valid, stage2_valid;
    wire stage1_ready, stage2_ready;
    
    // 反压控制逻辑
    assign stage2_ready = m_axis_tready || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign s_axis_tready = stage1_ready;
    
    // 第一级流水线 - 直接寄存取反后的结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bits_stage1 <= 4'b0;
            inv_stage1 <= 4'b0;
            stage1_valid <= 1'b0;
        end
        else if (s_axis_tvalid && s_axis_tready) begin
            bits_stage1 <= s_axis_tdata;
            inv_stage1 <= inv_comb1;  // 直接寄存已计算好的取反结果
            stage1_valid <= 1'b1;
        end
        else if (stage1_ready) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 第二级流水线 - 直接寄存最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inv_stage2 <= 4'b0;
            stage2_valid <= 1'b0;
        end
        else if (stage1_valid && stage1_ready) begin
            inv_stage2 <= inv_comb2;
            stage2_valid <= 1'b1;
        end
        else if (stage2_ready) begin
            stage2_valid <= 1'b0;
        end
    end
    
    // 将最终结果连接到输出
    assign m_axis_tdata = inv_stage2;
    assign m_axis_tvalid = stage2_valid;
    
endmodule