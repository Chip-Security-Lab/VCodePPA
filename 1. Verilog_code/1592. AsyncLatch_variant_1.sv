//SystemVerilog
module AsyncLatch #(parameter WIDTH=4) (
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    // 实例化锁存器单元
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : latch_array
            LatchCell latch_inst (
                .en(en),
                .data_in(data_in[i]),
                .data_out(data_out[i])
            );
        end
    endgenerate

endmodule

// 单比特锁存器单元
module LatchCell (
    input en,
    input data_in,
    output reg data_out
);
    always @* if(en) data_out = data_in;
endmodule