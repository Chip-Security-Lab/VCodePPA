//SystemVerilog
module dynamic_parity_checker #(
    parameter MAX_WIDTH = 64
)(
    input [$clog2(MAX_WIDTH)-1:0] width,
    input [MAX_WIDTH-1:0] data,
    output parity
);

    wire [MAX_WIDTH:0] xor_chain;
    
    // 实例化宽度控制模块
    width_controller #(
        .MAX_WIDTH(MAX_WIDTH)
    ) width_ctrl (
        .width(width),
        .data(data),
        .xor_chain(xor_chain)
    );
    
    // 实例化奇偶校验计算模块
    parity_calculator #(
        .MAX_WIDTH(MAX_WIDTH)
    ) parity_calc (
        .xor_chain(xor_chain),
        .parity(parity)
    );

endmodule

module width_controller #(
    parameter MAX_WIDTH = 64
)(
    input [$clog2(MAX_WIDTH)-1:0] width,
    input [MAX_WIDTH-1:0] data,
    output [MAX_WIDTH:0] xor_chain
);
    genvar i;
    assign xor_chain[0] = 0;
    
    generate
        for (i=0; i<MAX_WIDTH; i=i+1) begin : gen_xor
            assign xor_chain[i+1] = (i < width) ? 
                xor_chain[i] ^ data[i] : xor_chain[i];
        end
    endgenerate
endmodule

module parity_calculator #(
    parameter MAX_WIDTH = 64
)(
    input [MAX_WIDTH:0] xor_chain,
    output parity
);
    assign parity = xor_chain[MAX_WIDTH];
endmodule