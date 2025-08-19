//SystemVerilog
module d_latch (
    input wire d,
    input wire latch_en,
    output reg q
);
    always @* begin
        if (latch_en)
            q = d;
    end
endmodule

module tri_state_buffer (
    input wire data_in,
    input wire enable,
    output reg data_out
);
    always @* begin
        if (enable)
            data_out = data_in;
        else
            data_out = 1'bz;
    end
endmodule

module d_latch_out_enable (
    input wire d,
    input wire latch_en,
    input wire out_en,
    output wire q
);
    wire latch_out;
    
    d_latch latch_inst (
        .d(d),
        .latch_en(latch_en),
        .q(latch_out)
    );
    
    tri_state_buffer buffer_inst (
        .data_in(latch_out),
        .enable(out_en),
        .data_out(q)
    );
endmodule