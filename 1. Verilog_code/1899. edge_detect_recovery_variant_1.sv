//SystemVerilog
module edge_detect_recovery_axis (
    input wire clk,             // 时钟信号
    input wire rst_n,           // 低电平有效复位信号
    
    // AXI-Stream Slave接口
    input wire [7:0] s_axis_tdata,  // 输入数据
    input wire s_axis_tvalid,       // 输入数据有效
    output wire s_axis_tready,      // 准备接收数据
    input wire s_axis_tlast,        // 输入数据帧结束标志
    
    // AXI-Stream Master接口
    output reg [7:0] m_axis_tdata,  // 输出数据
    output reg m_axis_tvalid,       // 输出数据有效
    input wire m_axis_tready,       // 下游准备接收数据
    output reg m_axis_tlast         // 输出数据帧结束标志
);
    reg signal_prev;
    reg [7:0] edge_count;
    wire signal_in;
    reg rising_edge;
    reg falling_edge;
    wire edge_detected;
    
    // 从AXI-Stream输入中提取信号
    assign signal_in = s_axis_tdata[0]; // 使用输入数据的最低位作为信号输入
    
    // 主接口始终准备接收新数据
    assign s_axis_tready = 1'b1;
    
    // 优化边缘检测逻辑
    assign edge_detected = signal_in ^ signal_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_prev <= 1'b0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
            edge_count <= 8'h00;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'h00;
            m_axis_tlast <= 1'b0;
        end else begin
            // 当有有效输入数据时处理边沿检测
            if (s_axis_tvalid) begin  // 优化条件检查，移除冗余检查
                signal_prev <= signal_in;
                
                // 优化后的边沿检测逻辑
                rising_edge <= signal_in & ~signal_prev;
                falling_edge <= ~signal_in & signal_prev;
                
                // 使用预计算的edge_detected信号优化计数逻辑
                if (edge_detected)
                    edge_count <= edge_count + 1'b1;
                    
                // 准备输出数据
                m_axis_tdata <= {6'b0, falling_edge, rising_edge};
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= s_axis_tlast;
            end else if (m_axis_tvalid && m_axis_tready) begin
                // 一旦当前数据被接收，发送边沿计数
                m_axis_tdata <= edge_count;
                m_axis_tlast <= 1'b1;  // 标记为最后一个传输
            end else if (!(m_axis_tvalid && !m_axis_tready)) begin
                // 优化条件逻辑：否定"保持当前输出直到下游准备好"的情况
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end
endmodule