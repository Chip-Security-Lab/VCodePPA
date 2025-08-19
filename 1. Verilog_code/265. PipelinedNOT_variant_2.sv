//SystemVerilog
module PipelinedNOT(
    input clk,
    input rst_n,
    
    // AXI-Stream Slave Interface
    input [31:0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready,
    
    // AXI-Stream Master Interface
    output [31:0] m_axis_tdata,
    output m_axis_tvalid,
    input m_axis_tready,
    output m_axis_tlast
);

    // 改为两阶段流水线，使用寄存器传递数据，并优化逻辑
    reg [31:0] data_reg;
    reg valid_reg, last_reg;
    reg tready_reg;
    
    // 使用组合逻辑控制握手信号，减少时钟周期延迟
    assign s_axis_tready = tready_reg;
    assign m_axis_tdata = data_reg;
    assign m_axis_tvalid = valid_reg;
    assign m_axis_tlast = last_reg;
    
    // 数据和状态管理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 32'b0;
            valid_reg <= 1'b0;
            last_reg <= 1'b0;
            tready_reg <= 1'b1;
        end else begin
            // 使用单一流水线阶段，简化控制逻辑
            if (s_axis_tvalid && tready_reg) begin
                // 直接进行按位取反操作
                data_reg <= ~s_axis_tdata;
                valid_reg <= 1'b1;
                last_reg <= 1'b1;
                
                // 基于下游状态动态调整准备状态
                tready_reg <= m_axis_tready;
            end else if (m_axis_tready) begin
                // 数据已被接受，清除有效标志
                valid_reg <= 1'b0;
                last_reg <= 1'b0;
                
                // 准备接受新数据
                tready_reg <= 1'b1;
            end
        end
    end

endmodule