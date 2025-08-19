module cam_1 (
    input  wire        aclk,                // 时钟，原clk重命名
    input  wire        aresetn,             // 低电平有效复位，原rst取反并重命名
    
    // AXI-Stream Slave接口（输入）
    input  wire [7:0]  s_axis_tdata,        // 输入数据
    input  wire        s_axis_tvalid,       // 输入数据有效
    output wire        s_axis_tready,       // 接收端准备好
    input  wire        s_axis_tlast,        // 输入帧结束信号
    
    // AXI-Stream Master接口（输出）
    output wire [8:0]  m_axis_tdata,        // 输出数据，包含匹配标志和存储数据
    output reg         m_axis_tvalid,       // 输出数据有效
    input  wire        m_axis_tready,       // 接收端准备好
    output reg         m_axis_tlast         // 输出帧结束信号
);

    // 内部信号
    reg  [7:0] store_data;
    reg        match_flag;
    reg  [1:0] ctrl_state;
    reg        write_mode;
    wire       rst;
    
    // 转换复位信号（从低电平有效转为高电平有效）
    assign rst = ~aresetn;
    
    // AXI-Stream握手逻辑
    assign s_axis_tready = aresetn && (ctrl_state != 2'b01); // 非复位状态时准备接收数据
    
    // 输出数据组合
    assign m_axis_tdata = {match_flag, store_data};
    
    // 确定当前操作模式（写入或匹配）
    always @(*) begin
        if (s_axis_tvalid && s_axis_tready) begin
            write_mode = s_axis_tlast; // 使用tlast信号决定是写入模式(1)还是匹配模式(0)
        end else begin
            write_mode = 1'b0;
        end
    end
    
    // 控制状态逻辑
    always @(*) begin
        case ({rst, write_mode})
            2'b10, 2'b11: ctrl_state = 2'b01; // 复位状态优先
            2'b01:        ctrl_state = 2'b10; // 写入状态
            2'b00:        ctrl_state = 2'b11; // 匹配状态
            default:      ctrl_state = 2'b01; // 默认为复位状态
        endcase
    end
    
    // 主状态机
    always @(posedge aclk) begin
        if (rst) begin
            // 复位所有寄存器
            store_data <= 8'b0;
            match_flag <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            case (ctrl_state)
                2'b01: begin // 复位状态（不应该进入，因为复位时s_axis_tready为0）
                    store_data <= 8'b0;
                    match_flag <= 1'b0;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                end
                2'b10: begin // 写入状态
                    store_data <= s_axis_tdata;
                    match_flag <= match_flag;  // 保持不变
                    m_axis_tvalid <= 1'b1;     // 数据更新后，输出有效
                    m_axis_tlast <= 1'b1;      // 写操作结束
                end
                2'b11: begin // 匹配状态
                    store_data <= store_data;  // 保持不变
                    match_flag <= (store_data == s_axis_tdata);
                    m_axis_tvalid <= 1'b1;     // 匹配结果有效
                    m_axis_tlast <= 1'b1;      // 匹配操作结束
                end
                default: begin // 安全默认值
                    store_data <= 8'b0;
                    match_flag <= 1'b0;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                end
            endcase
        end else if (m_axis_tvalid && m_axis_tready) begin
            // 当下游接收到数据后，清除valid信号
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end
    end

endmodule