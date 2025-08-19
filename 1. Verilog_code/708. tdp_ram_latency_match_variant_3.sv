//SystemVerilog
module borrow_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow
);

reg [WIDTH-1:0] diff_reg;
reg borrow_reg;
reg [WIDTH:0] temp;
integer i;

always @(*) begin
    temp = {1'b0, a};
    for (i = 0; i < WIDTH; i = i + 1) begin
        if (temp[i] < b[i]) begin
            temp[i+1] = temp[i+1] - 1'b1;
            temp[i] = temp[i] + 2'b10;
        end
        diff_reg[i] = temp[i] - b[i];
    end
    borrow_reg = temp[WIDTH];
end

assign diff = diff_reg;
assign borrow = borrow_reg;

endmodule

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

// 新增信号用于地址计算
wire [AW-1:0] m_addr_adj;
wire [AW-1:0] n_addr_adj;
wire m_borrow, n_borrow;

// 实例化借位减法器
borrow_subtractor #(
    .WIDTH(AW)
) m_addr_sub (
    .a(m_addr),
    .b(1'b1),
    .diff(m_addr_adj),
    .borrow(m_borrow)
);

borrow_subtractor #(
    .WIDTH(AW)
) n_addr_sub (
    .a(n_addr),
    .b(1'b1),
    .diff(n_addr_adj),
    .borrow(n_borrow)
);

genvar i, j;
generate
    // Port M管道
    always @(posedge clk) begin
        if (m_we) mem[m_addr] <= m_din;
        m_pipe[0] <= mem[m_addr_adj]; // 使用调整后的地址
    end
    
    for (i=1; i<LATENCY; i=i+1) begin : m_pipeline
        always @(posedge clk) begin
            m_pipe[i] <= m_pipe[i-1];
        end
    end
    
    // Port N管道
    always @(posedge clk) begin
        if (n_we) mem[n_addr] <= n_din;
        n_pipe[0] <= mem[n_addr_adj]; // 使用调整后的地址
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