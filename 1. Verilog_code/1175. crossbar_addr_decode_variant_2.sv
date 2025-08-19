//SystemVerilog
module crossbar_addr_decode #(parameter AW=4, parameter DW=16, parameter N=8) (
    input clk,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output [N*DW-1:0] data_out
);
    reg [N-1:0] sel;
    reg [DW-1:0] out_array [0:N-1];
    integer i;

    always @(*) begin
        sel = 0;
        if(addr < N) sel[addr] = 1'b1;

        for(i=0; i<N; i=i+1) begin
            if(sel[i]) begin
                out_array[i] = data_in;
            end else begin
                out_array[i] = 0;
            end
        end
    end

    genvar g;
    generate 
        for(g=0; g<N; g=g+1) begin: gen_out
            assign data_out[(g*DW) +: DW] = out_array[g];
        end
    endgenerate
endmodule