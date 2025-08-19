//SystemVerilog
module digital_ctrl_osc (
    // AXI-Stream Slave接口
    input wire          s_axis_aclk,
    input wire          s_axis_aresetn,
    input wire          s_axis_tvalid,
    output wire         s_axis_tready,
    input wire [7:0]    s_axis_tdata,
    
    // AXI-Stream Master接口
    output wire         m_axis_tvalid,
    input wire          m_axis_tready,
    output wire         m_axis_tdata
);
    // 内部信号定义
    reg [7:0] delay_counter;
    reg clk_out_reg;
    wire enable;
    wire [7:0] ctrl_word;
    
    // 控制信号映射
    assign enable = s_axis_tvalid & s_axis_tready;
    assign ctrl_word = s_axis_tdata;
    assign s_axis_tready = 1'b1; // 总是准备好接收新的控制字
    
    // 输出映射
    assign m_axis_tvalid = 1'b1; // 输出始终有效
    assign m_axis_tdata = clk_out_reg;
    
    // 计数器逻辑 - 优化比较操作
    always @(posedge s_axis_aclk or negedge s_axis_aresetn) begin
        if (!s_axis_aresetn) begin
            delay_counter <= 8'd0;
            clk_out_reg <= 1'b0;
        end else if (enable) begin
            // 优化后的比较逻辑：使用相等比较替代大于等于比较
            // 这可以减少比较器的复杂度并提高时序性能
            if (delay_counter == ctrl_word) begin
                delay_counter <= 8'd0;
                clk_out_reg <= ~clk_out_reg;
            end else begin
                delay_counter <= delay_counter + 8'd1;
            end
        end
    end
endmodule