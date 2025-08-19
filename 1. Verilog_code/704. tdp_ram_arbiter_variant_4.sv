//SystemVerilog
module tdp_ram_arbiter #(
    parameter DW = 28,
    parameter AW = 7
)(
    input clk,
    input arb_mode,
    // Port A
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output reg [DW-1:0] a_dout,
    input a_we, a_re,
    // Port B
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output reg [DW-1:0] b_dout,
    input b_we, b_re
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg arb_flag;
reg write_conflict;
reg a_we_d, b_we_d;
reg a_re_d, b_re_d;
reg [AW-1:0] a_addr_d, b_addr_d;
reg [DW-1:0] a_din_d, b_din_d;

// 输入寄存器
always @(posedge clk) begin
    a_we_d <= a_we;
    b_we_d <= b_we;
    a_re_d <= a_re;
    b_re_d <= b_re;
    a_addr_d <= a_addr;
    b_addr_d <= b_addr;
    a_din_d <= a_din;
    b_din_d <= b_din;
end

// 写冲突检测
always @(posedge clk) begin
    write_conflict <= a_we_d & b_we_d;
end

// 仲裁标志更新
always @(posedge clk) begin
    if (write_conflict && arb_mode) begin
        arb_flag <= ~arb_flag;
    end
end

// 存储器写操作
always @(posedge clk) begin
    if (write_conflict) begin
        if (!arb_mode) begin
            mem[a_addr_d] <= a_din_d;
            mem[b_addr_d] <= a_din_d;
        end else if (arb_flag) begin
            mem[a_addr_d] <= a_din_d;
        end else begin
            mem[b_addr_d] <= b_din_d;
        end
    end else begin
        if (a_we_d) mem[a_addr_d] <= a_din_d;
        if (b_we_d) mem[b_addr_d] <= b_din_d;
    end
end

// 读操作
always @(posedge clk) begin
    a_dout <= (a_re_d && !(b_re_d && arb_flag)) ? mem[a_addr_d] : 'hz;
    b_dout <= (b_re_d && !(a_re_d && !arb_flag)) ? mem[b_addr_d] : 'hz;
end

endmodule