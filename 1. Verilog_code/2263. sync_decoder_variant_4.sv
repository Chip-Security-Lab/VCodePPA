//SystemVerilog - IEEE 1364-2005
// 顶层模块
module sync_decoder (
    input wire clk,
    input wire rst_n,
    
    // 输入AXI-Stream接口
    input wire [2:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // 输出AXI-Stream接口
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);
    // 内部AXI-Stream连接
    wire [2:0] stage1_tdata;
    wire stage1_tvalid;
    wire stage1_tready;
    
    wire [7:0] stage2_tdata;
    wire stage2_tvalid;
    wire stage2_tready;

    // 实例化第一级流水线寄存器模块
    pipeline_stage1 u_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(stage1_tdata),
        .m_axis_tvalid(stage1_tvalid),
        .m_axis_tready(stage1_tready)
    );

    // 实例化解码器模块
    decoder_stage u_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(stage1_tdata),
        .s_axis_tvalid(stage1_tvalid),
        .s_axis_tready(stage1_tready),
        .m_axis_tdata(stage2_tdata),
        .m_axis_tvalid(stage2_tvalid),
        .m_axis_tready(stage2_tready)
    );

    // 实例化输出寄存器模块
    output_stage u_output (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(stage2_tdata),
        .s_axis_tvalid(stage2_tvalid),
        .s_axis_tready(stage2_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

endmodule

// 第一级流水线寄存器模块
module pipeline_stage1 (
    input wire clk,
    input wire rst_n,
    
    // 输入AXI-Stream接口
    input wire [2:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    
    // 输出AXI-Stream接口
    output reg [2:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);
    // 寄存地址和有效信号，实现AXI-Stream握手机制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 3'b0;
            m_axis_tvalid <= 1'b0;
            s_axis_tready <= 1'b0;
        end
        else begin
            s_axis_tready <= m_axis_tready || !m_axis_tvalid;
            
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata <= s_axis_tdata;
                m_axis_tvalid <= 1'b1;
            end
            else if (m_axis_tready && m_axis_tvalid) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end
endmodule

// 解码器模块
module decoder_stage (
    input wire clk,
    input wire rst_n,
    
    // 输入AXI-Stream接口
    input wire [2:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    
    // 输出AXI-Stream接口
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);
    // 执行解码操作，实现AXI-Stream握手机制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 8'b0;
            m_axis_tvalid <= 1'b0;
            s_axis_tready <= 1'b0;
        end
        else begin
            s_axis_tready <= m_axis_tready || !m_axis_tvalid;
            
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata <= (8'b1 << s_axis_tdata);
                m_axis_tvalid <= 1'b1;
            end
            else if (m_axis_tready && m_axis_tvalid) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end
endmodule

// 输出寄存器模块
module output_stage (
    input wire clk,
    input wire rst_n,
    
    // 输入AXI-Stream接口
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    
    // 输出AXI-Stream接口
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);
    // 最终输出级，实现AXI-Stream握手机制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata <= 8'b0;
            m_axis_tvalid <= 1'b0;
            s_axis_tready <= 1'b0;
        end
        else begin
            s_axis_tready <= m_axis_tready || !m_axis_tvalid;
            
            if (s_axis_tvalid && s_axis_tready) begin
                m_axis_tdata <= s_axis_tdata;
                m_axis_tvalid <= 1'b1;
            end
            else if (m_axis_tready && m_axis_tvalid) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end
endmodule