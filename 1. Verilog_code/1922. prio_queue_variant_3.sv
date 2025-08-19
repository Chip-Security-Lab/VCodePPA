//SystemVerilog
module prio_queue #(parameter DW=8, SIZE=4) (
    input  [DW*SIZE-1:0] data_in,
    output [DW-1:0]      data_out
);
    wire [DW-1:0] entries [0:SIZE-1];

    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin: entry_split
            assign entries[i] = data_in[(i+1)*DW-1:i*DW];
        end
    endgenerate

    wire valid3 = |entries[3];
    wire valid2 = |entries[2];
    wire valid1 = |entries[1];

    assign data_out = (valid3)                ? entries[3] :
                      (~valid3 & valid2)      ? entries[2] :
                      (~valid3 & ~valid2 & valid1) ? entries[1] :
                                                     entries[0];

endmodule