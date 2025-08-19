//SystemVerilog
module Demux_SyncEn #(parameter DW=8, AW=3) (
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    output reg [(1<<AW)-1:0][DW-1:0] data_out
);
    integer i;
    reg [(1<<AW)-1:0][DW-1:0] next_data_out;
    
    // Barrel shifter implementation using multiplexers
    always @(*) begin
        next_data_out = 0;
        for (i = 0; i < (1<<AW); i = i + 1) begin
            if (i == addr)
                next_data_out[i] = data_in;
            else
                next_data_out[i] = 0;
        end
    end
    
    // Sequential logic with reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            data_out <= 0;
        else if (en)
            data_out <= next_data_out;
    end
endmodule