//SystemVerilog
module spread_spectrum_clk (
    input  wire        aclk,              // 系统时钟
    input  wire        aresetn,           // 低电平有效复位信号
    
    // AXI-Stream 输入接口
    input  wire        s_axis_tvalid,     // 输入数据有效
    output wire        s_axis_tready,     // 模块准备接收
    input  wire [3:0]  s_axis_tdata,      // 传输的spread_amount数据
    input  wire        s_axis_tlast,      // 表示enable_spread的状态
    
    // AXI-Stream 输出接口
    output reg         m_axis_tvalid,     // 输出数据有效
    input  wire        m_axis_tready,     // 下游准备接收
    output reg         m_axis_tdata,      // 时钟输出作为数据
    output reg         m_axis_tlast       // 周期完成指示
);

    // 内部信号
    reg [3:0] counter, period;
    reg direction;
    reg clock_out;
    reg processing_active;
    
    // AXI-Stream流控制逻辑
    assign s_axis_tready = aresetn && processing_active;
    
    // 核心处理逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            counter <= 4'b0;
            period <= 4'd8;
            direction <= 1'b0;
            clock_out <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 1'b0;
            m_axis_tlast <= 1'b0;
            processing_active <= 1'b1;
        end else begin
            // 默认状态
            m_axis_tvalid <= 1'b1;
            
            if (counter >= period) begin
                counter <= 4'b0;
                clock_out <= ~clock_out;
                m_axis_tdata <= ~clock_out;
                m_axis_tlast <= 1'b1; // 标记周期结束
                
                // 只有在上游数据有效时更新周期
                if (s_axis_tvalid && s_axis_tready) begin
                    // Update period for next half-cycle
                    if (s_axis_tlast) begin // 使用tlast作为enable_spread
                        if (direction) begin
                            if (period < 4'd8 + s_axis_tdata)
                                period <= period + 4'd1;
                            else
                                direction <= 1'b0;
                        end else begin
                            if (period > 4'd8 - s_axis_tdata)
                                period <= period - 4'd1;
                            else
                                direction <= 1'b1;
                        end
                    end else
                        period <= 4'd8;
                end
            end else begin
                counter <= counter + 4'b1;
                m_axis_tlast <= 1'b0; // 非周期结束
                m_axis_tdata <= clock_out; // 保持当前时钟状态
            end
            
            // 当下游准备好接收时，继续处理
            processing_active <= m_axis_tready;
        end
    end
endmodule