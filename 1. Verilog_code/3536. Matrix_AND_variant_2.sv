//SystemVerilog
// SystemVerilog
module Matrix_AND (
    // AXI-Stream接口 - 输入
    input  wire        aclk,           // 时钟信号
    input  wire        aresetn,        // 复位信号，低电平有效
    
    // 输入数据流
    input  wire [7:0]  s_axis_tdata,   // 输入数据 {row, col}
    input  wire        s_axis_tvalid,  // 输入数据有效信号
    output wire        s_axis_tready,  // 准备接收数据信号
    input  wire        s_axis_tlast,   // 数据包结束信号
    
    // 输出数据流
    output reg  [7:0]  m_axis_tdata,   // 输出处理结果
    output wire        m_axis_tvalid,  // 输出数据有效信号
    input  wire        m_axis_tready,  // 下游模块准备接收数据
    output reg         m_axis_tlast    // 输出数据包结束信号
);

    // 状态编码优化：使用独热码编码以降低功耗
    localparam [2:0] IDLE    = 3'b001;
    localparam [2:0] PROCESS = 3'b010;
    localparam [2:0] SEND    = 3'b100;
    
    reg [2:0] state;
    
    // 数据寄存器
    reg [7:0] data_reg;
    reg       tlast_reg;
    
    // 状态机控制信号 - 转为组合逻辑，避免额外时钟周期延迟
    reg  s_ready_i;
    reg  m_valid_i;
    
    // 输出连线绑定
    assign s_axis_tready = s_ready_i;
    assign m_axis_tvalid = m_valid_i;

    // 常量掩码 - 用parameter定义，更易于修改
    parameter [7:0] MASK = 8'h55;
    
    // 简化的单进程状态机，降低逻辑深度
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            data_reg <= 8'h00;
            tlast_reg <= 1'b0;
            m_axis_tdata <= 8'h00;
            m_axis_tlast <= 1'b0;
            s_ready_i <= 1'b1;
            m_valid_i <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_ready_i) begin
                        // 捕获输入数据并提前计算结果
                        data_reg <= s_axis_tdata & MASK;
                        tlast_reg <= s_axis_tlast;
                        s_ready_i <= 1'b0;
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    // 减少状态转换时间，直接进入发送状态
                    m_axis_tdata <= data_reg;
                    m_axis_tlast <= tlast_reg;
                    m_valid_i <= 1'b1;
                    state <= SEND;
                end
                
                SEND: begin
                    if (m_axis_tready) begin
                        m_valid_i <= 1'b0;
                        s_ready_i <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule