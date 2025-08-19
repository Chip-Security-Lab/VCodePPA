//SystemVerilog
module auto_reload_timer (
    input wire clk,                  // 时钟信号
    input wire rstn,                 // 复位信号，低电平有效
    
    // AXI-Stream 输入接口
    input wire [31:0] s_axis_tdata,  // 输入数据，包含reload_val
    input wire s_axis_tvalid,        // 输入数据有效
    input wire s_axis_tlast,         // 输入传输结束标志
    output wire s_axis_tready,       // 输入就绪信号
    
    // AXI-Stream 输出接口
    output reg [31:0] m_axis_tdata,  // 输出数据，包含count值
    output reg m_axis_tvalid,        // 输出数据有效
    output reg m_axis_tlast,         // 输出传输结束标志
    input wire m_axis_tready         // 输出就绪信号
);
    reg [31:0] reload_reg;
    reg [31:0] count;
    reg [31:0] count_buf1, count_buf2; // 添加count的缓冲寄存器
    reg timeout;
    reg en_reg;
    
    // s_axis_tvalid和s_axis_tready的缓冲寄存器
    reg s_axis_tvalid_buf1, s_axis_tvalid_buf2;
    reg s_axis_tready_int;
    wire s_axis_tready_buf1, s_axis_tready_buf2;
    
    // 为高扇出信号添加缓冲
    always @(posedge clk) begin
        if (!rstn) begin
            s_axis_tvalid_buf1 <= 1'b0;
            s_axis_tvalid_buf2 <= 1'b0;
        end
        else begin
            s_axis_tvalid_buf1 <= s_axis_tvalid;
            s_axis_tvalid_buf2 <= s_axis_tvalid;
        end
    end
    
    // 为count添加缓冲
    always @(posedge clk) begin
        if (!rstn) begin
            count_buf1 <= 32'h0;
            count_buf2 <= 32'h0;
        end
        else begin
            count_buf1 <= count;
            count_buf2 <= count;
        end
    end
    
    // AXI-Stream 控制逻辑
    assign s_axis_tready_buf1 = rstn;
    assign s_axis_tready_buf2 = rstn;
    assign s_axis_tready = s_axis_tready_int;
    
    always @(posedge clk) begin
        if (!rstn)
            s_axis_tready_int <= 1'b0;
        else
            s_axis_tready_int <= rstn; // 复位后就绪接收数据
    end
    
    // 使用扇出缓冲的信号b0
    reg b0, b0_buf1, b0_buf2, b0_buf3;
    
    always @(posedge clk) begin
        if (!rstn) begin
            b0 <= 1'b0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            b0_buf3 <= 1'b0;
        end
        else begin
            b0 <= en_reg || timeout;
            b0_buf1 <= b0;
            b0_buf2 <= b0;
            b0_buf3 <= b0;
        end
    end
    
    // 使能信号处理 - 从输入流控制
    always @(posedge clk) begin
        if (!rstn)
            en_reg <= 1'b0;
        else if (s_axis_tvalid_buf1 && s_axis_tready_int && !s_axis_tlast)
            en_reg <= 1'b1;
        else if (s_axis_tvalid_buf2 && s_axis_tready_int && s_axis_tlast)
            en_reg <= 1'b0;
    end
    
    // 重载寄存器逻辑
    always @(posedge clk) begin
        if (!rstn)
            reload_reg <= 32'hFFFFFFFF;
        else if (s_axis_tvalid_buf1 && s_axis_tready_int)
            reload_reg <= s_axis_tdata;
    end
    
    // 计数器和超时逻辑
    always @(posedge clk) begin
        if (!rstn) begin
            count <= 32'h0;
            timeout <= 1'b0;
        end
        else if (en_reg) begin
            if (count == reload_reg) begin
                count <= 32'h0;
                timeout <= 1'b1;
            end
            else begin
                count <= count + 32'h1;
                timeout <= 1'b0;
            end
        end
    end
    
    // AXI-Stream 输出逻辑
    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tdata <= 32'h0;
        end
        else begin
            // 使用缓冲的b0信号进行控制
            if (b0_buf1) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata <= count_buf1;
                m_axis_tlast <= timeout; // 超时时置位tlast
            end
            else if (m_axis_tready && m_axis_tvalid) begin
                // 数据被接收后，清除有效标志
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end
endmodule