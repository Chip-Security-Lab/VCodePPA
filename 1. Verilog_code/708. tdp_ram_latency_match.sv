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

genvar i, j;
generate
    // Port M管道
    always @(posedge clk) begin
        if (m_we) mem[m_addr] <= m_din;
        m_pipe[0] <= mem[m_addr];
    end
    
    for (i=1; i<LATENCY; i=i+1) begin : m_pipeline
        always @(posedge clk) begin
            m_pipe[i] <= m_pipe[i-1];
        end
    end
    
    // Port N管道
    always @(posedge clk) begin
        if (n_we) mem[n_addr] <= n_din;
        n_pipe[0] <= mem[n_addr];
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