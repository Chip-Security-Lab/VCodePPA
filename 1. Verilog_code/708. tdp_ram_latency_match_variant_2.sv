//SystemVerilog
module tdp_ram_latency_match #(
    parameter DW = 48,
    parameter AW = 9,
    parameter LATENCY = 3
)(
    input clk,
    // Port M
    input [AW-1:0] m_addr,
    input [DW-1:0] m_din,
    output [DW-1:0] m_dout,
    input m_we,
    // Port N
    input [AW-1:0] n_addr,
    input [DW-1:0] n_din,
    output [DW-1:0] n_dout,
    input n_we
);

(* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] m_pipe [0:LATENCY-1];
reg [DW-1:0] n_pipe [0:LATENCY-1];

// 输入缓冲寄存器
reg [AW-1:0] m_addr_buf;
reg [AW-1:0] n_addr_buf;
reg [DW-1:0] m_din_buf;
reg [DW-1:0] n_din_buf;
reg m_we_buf;
reg n_we_buf;

// 中间流水线寄存器
reg [AW-1:0] m_addr_pipe;
reg [AW-1:0] n_addr_pipe;
reg [DW-1:0] m_din_pipe;
reg [DW-1:0] n_din_pipe;
reg m_we_pipe;
reg n_we_pipe;

// 第一级输入缓冲
always @(posedge clk) begin
    m_addr_buf <= m_addr;
    n_addr_buf <= n_addr;
    m_din_buf <= m_din;
    n_din_buf <= n_din;
    m_we_buf <= m_we;
    n_we_buf <= n_we;
end

// 第二级输入缓冲
always @(posedge clk) begin
    m_addr_pipe <= m_addr_buf;
    n_addr_pipe <= n_addr_buf;
    m_din_pipe <= m_din_buf;
    n_din_pipe <= n_din_buf;
    m_we_pipe <= m_we_buf;
    n_we_pipe <= n_we_buf;
end

genvar i, j;
generate
    // Port M管道
    always @(posedge clk) begin
        if (m_we_pipe) mem[m_addr_pipe] <= m_din_pipe;
        m_pipe[0] <= mem[m_addr_pipe];
    end
    
    for (i=1; i<LATENCY; i=i+1) begin : m_pipeline
        always @(posedge clk) begin
            m_pipe[i] <= m_pipe[i-1];
        end
    end
    
    // Port N管道
    always @(posedge clk) begin
        if (n_we_pipe) mem[n_addr_pipe] <= n_din_pipe;
        n_pipe[0] <= mem[n_addr_pipe];
    end
    
    for (j=1; j<LATENCY; j=j+1) begin : n_pipeline
        always @(posedge clk) begin
            n_pipe[j] <= n_pipe[j-1];
        end
    end
endgenerate

assign m_dout = m_pipe[LATENCY-1];
assign n_dout = n_pipe[LATENCY-1];
endmodule