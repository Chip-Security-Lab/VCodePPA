//SystemVerilog
module manchester_encoder (
    input wire clk,
    input wire rst,
    
    // AXI-Stream 输入接口
    input wire [0:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream 输出接口
    output reg [0:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);
    // 内部信号
    reg clk_div;
    reg data_in_reg;
    reg processing;
    
    // 输入端准备好接收新数据
    assign s_axis_tready = !processing || m_axis_tready;
    
    // 时钟分频逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
        end else if (processing) begin
            clk_div <= ~clk_div; // 将时钟频率除以2
        end
    end
    
    // 输入数据捕获逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready && !processing) begin
            data_in_reg <= s_axis_tdata[0];
        end
    end
    
    // 处理状态控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            processing <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !processing) begin
                processing <= 1;
            end else if (m_axis_tready && clk_div && processing) begin
                processing <= 0;
            end
        end
    end
    
    // 曼彻斯特编码输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata <= 0;
            m_axis_tvalid <= 0;
        end else begin
            if (processing) begin
                m_axis_tdata[0] <= data_in_reg ^ clk_div; // 曼彻斯特编码
                m_axis_tvalid <= 1;
            end else begin
                m_axis_tvalid <= 0;
            end
        end
    end
endmodule