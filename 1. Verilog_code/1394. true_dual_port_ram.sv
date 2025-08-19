module true_dual_port_ram #(parameter DW=16, AW=8) (
    input clk_a, clk_b,
    input [AW-1:0] addr_a, addr_b,
    input wr_a, wr_b,
    input [DW-1:0] din_a, din_b,
    output reg [DW-1:0] dout_a, dout_b
);
    reg [DW-1:0] mem [(1<<AW)-1:0];
    
    always @(posedge clk_a) begin
        if(wr_a) mem[addr_a] <= din_a;
        dout_a <= mem[addr_a];
    end
    
    always @(posedge clk_b) begin
        if(wr_b) mem[addr_b] <= din_b;
        dout_b <= mem[addr_b];
    end
endmodule
