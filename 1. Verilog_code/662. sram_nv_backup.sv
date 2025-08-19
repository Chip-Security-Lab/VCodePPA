module sram_nv_backup #(
    parameter DW = 8,
    parameter AW = 10
)(
    input clk,
    input power_good,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] volatile_mem [0:(1<<AW)-1];
reg [DW-1:0] nv_mem [0:(1<<AW)-1];
integer i;

always @(posedge clk) begin
    if (!power_good) begin
        // Backup restore - need to handle array copy iteratively
        for (i=0; i<(1<<AW); i=i+1) begin
            volatile_mem[i] <= nv_mem[i]; 
        end
    end else if (we) begin
        volatile_mem[addr] <= din;
        nv_mem[addr] <= din;    // Shadow write
    end
end

assign dout = volatile_mem[addr];
endmodule