//SystemVerilog
module pipeline_regfile #(
    parameter DW = 64,
    parameter AW = 3,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] mem [0:DEPTH-1];
reg [DW-1:0] mem_buf1, mem_buf2;  // 缓冲寄存器，分散mem的负载
reg [DW-1:0] pipe_reg1, pipe_reg2;
reg [AW-1:0] addr_reg;  // 寄存器化地址信号
integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i=0; i<DEPTH; i=i+1) mem[i] <= {DW{1'b0}};
        mem_buf1 <= {DW{1'b0}};
        mem_buf2 <= {DW{1'b0}};
        pipe_reg1 <= {DW{1'b0}};
        pipe_reg2 <= {DW{1'b0}};
        addr_reg <= {AW{1'b0}};
    end else begin
        if (wr_en) mem[addr] <= din;
        addr_reg <= addr;  // 寄存器化地址，减少关键路径负载
        mem_buf1 <= mem[addr_reg];  // 从mem读取数据到缓冲寄存器1
        mem_buf2 <= mem_buf1;       // 级联缓冲
        pipe_reg1 <= mem_buf2;      // 使用缓冲后的数据
        pipe_reg2 <= pipe_reg1;
    end
end

assign dout = pipe_reg2;
endmodule