//SystemVerilog
module tdp_ram_latency_match #(
    parameter DW = 48,
    parameter AW = 9,
    parameter LATENCY = 2
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

// Memory write control for Port M
always @(posedge clk) begin
    if (m_we) begin
        mem[m_addr] <= m_din;
    end
end

// Memory write control for Port N
always @(posedge clk) begin
    if (n_we) begin
        mem[n_addr] <= n_din;
    end
end

// Port M read pipeline stage 0
always @(posedge clk) begin
    m_pipe[0] <= mem[m_addr];
end

// Port M read pipeline stage 1
always @(posedge clk) begin
    m_pipe[1] <= m_pipe[0];
end

// Port N read pipeline stage 0
always @(posedge clk) begin
    n_pipe[0] <= mem[n_addr];
end

// Port N read pipeline stage 1
always @(posedge clk) begin
    n_pipe[1] <= n_pipe[0];
end

assign m_dout = m_pipe[LATENCY-1];
assign n_dout = n_pipe[LATENCY-1];

endmodule