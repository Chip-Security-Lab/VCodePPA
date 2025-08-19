module crossbar_addr_decode #(parameter AW=4, parameter DW=16, parameter N=8) (
    input clk,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output [N*DW-1:0] data_out // 打平的数组
);
reg [N-1:0] sel;
integer i;

always @(*) begin
    sel = 0;
    if(addr < N) sel[addr] = 1'b1;
end

genvar g;
generate 
    for(g=0; g<N; g=g+1) begin: gen_out
        assign data_out[(g*DW) +: DW] = sel[g] ? data_in : 0;
    end
endgenerate
endmodule