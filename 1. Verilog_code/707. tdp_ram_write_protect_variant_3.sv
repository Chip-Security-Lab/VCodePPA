//SystemVerilog
module tdp_ram_write_protect #(
    parameter DW = 20,
    parameter AW = 8
)(
    input clk,
    input [AW-1:0] protect_start,
    input [AW-1:0] protect_end,
    // Port1
    input [AW-1:0] addr1,
    input [DW-1:0] din1,
    output reg [DW-1:0] dout1,
    input we1,
    // Port2
    input [AW-1:0] addr2,
    input [DW-1:0] din2,
    output reg [DW-1:0] dout2,
    input we2
);

reg [DW-1:0] mem [0:(1<<AW)-1];

// 补码减法实现
wire [AW:0] sub_result1;
wire [AW:0] sub_result2;
wire [AW:0] sub_result3;
wire [AW:0] sub_result4;

assign sub_result1 = {1'b0, addr1} - {1'b0, protect_start};
assign sub_result2 = {1'b0, protect_end} - {1'b0, addr1};
assign sub_result3 = {1'b0, addr2} - {1'b0, protect_start};
assign sub_result4 = {1'b0, protect_end} - {1'b0, addr2};

wire is_protected1 = !sub_result1[AW] && !sub_result2[AW];
wire is_protected2 = !sub_result3[AW] && !sub_result4[AW];

always @(posedge clk) begin
    // Port1写入
    if (we1 && !is_protected1)
        mem[addr1] <= din1;
    dout1 <= mem[addr1];
    
    // Port2写入
    if (we2 && !is_protected2)
        mem[addr2] <= din2;
    dout2 <= mem[addr2];
end

endmodule