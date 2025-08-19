//SystemVerilog
// 顶层模块
module MuxWithSubtractor #(parameter W=8, ADDR_W=2) (
    input [(2**ADDR_W)-1:0][W-1:0] ch,
    input [ADDR_W-1:0] addr,
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] out,
    output [W-1:0] diff,
    output borrow
);
    wire [W-1:0] mux_out;
    
    // 实例化多路选择器子模块
    MuxParamAddr #(.W(W), .ADDR_W(ADDR_W)) mux_inst (
        .ch(ch),
        .addr(addr),
        .out(mux_out)
    );
    
    // 实例化条件减法器子模块
    ConditionalInversionSubtractor #(.W(W)) sub_inst (
        .a(a),
        .b(b),
        .diff(diff),
        .borrow(borrow)
    );
    
    assign out = mux_out;
endmodule

// 多路选择器子模块
module MuxParamAddr #(parameter W=8, ADDR_W=2) (
    input [(2**ADDR_W)-1:0][W-1:0] ch,
    input [ADDR_W-1:0] addr,
    output [W-1:0] out
);
    assign out = ch[addr];
endmodule

// 条件减法器子模块
module ConditionalInversionSubtractor #(parameter W=8) (
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] diff,
    output borrow
);
    wire [W-1:0] b_inv;
    wire [W-1:0] sum;
    wire [W:0] carry;
    
    assign b_inv = ~b;
    assign carry[0] = 1'b1;
    
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : add_chain
            assign sum[i] = a[i] ^ b_inv[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b_inv[i]) | (a[i] & carry[i]) | (b_inv[i] & carry[i]);
        end
    endgenerate
    
    assign diff = sum;
    assign borrow = ~carry[W];
endmodule