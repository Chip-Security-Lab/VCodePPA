//SystemVerilog
module decoder_multi_protocol (
    // 全局信号
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream 输入信号
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [16:0] s_axis_tdata,  // 16位数据 + 1位模式
    input wire s_axis_tlast,
    
    // AXI-Stream 输出信号
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [3:0] m_axis_tdata,
    output reg m_axis_tlast
);
    // 内部信号定义
    wire mode;
    wire [15:0] addr;
    reg [3:0] sel;
    
    // 解析输入数据
    assign mode = s_axis_tdata[16];
    assign addr = s_axis_tdata[15:0];
    
    // 握手逻辑 - 当没有输出背压且有有效输入时准备好接收数据
    assign s_axis_tready = !m_axis_tvalid || m_axis_tready;
    
    // 预先计算模式0和模式1的比较结果
    wire mode0_match = (addr[15:12] == 4'ha);
    wire mode1_match = (addr[7:4] == 4'h5);
    
    // 主处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 4'b0000;
            m_axis_tlast <= 1'b0;
        end
        else begin
            // 处理握手逻辑
            if (m_axis_tvalid && m_axis_tready) begin
                // 当前数据被接收，清除有效标志
                m_axis_tvalid <= 1'b0;
            end
            
            // 处理新的输入数据
            if (s_axis_tvalid && s_axis_tready) begin
                // 计算选择器值
                if ((mode == 1'b0 && mode0_match) || (mode == 1'b1 && mode1_match)) begin
                    m_axis_tdata <= addr[3:0];
                end
                else begin
                    m_axis_tdata <= 4'b0000;
                end
                
                // 设置输出有效和last标志
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= s_axis_tlast;
            end
        end
    end
    
endmodule