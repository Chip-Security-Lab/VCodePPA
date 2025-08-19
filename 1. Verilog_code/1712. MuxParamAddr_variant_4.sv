//SystemVerilog
// 顶层模块
module MuxParamAddr #(parameter W=8, ADDR_W=2) (
    input [(2**ADDR_W)-1:0][W-1:0] ch,
    input [ADDR_W-1:0] addr,
    output [W-1:0] out
);

    // 地址解码子模块
    addr_decoder #(
        .ADDR_W(ADDR_W)
    ) addr_decoder_inst (
        .addr(addr),
        .decoded_addr(decoded_addr)
    );

    // 数据选择子模块
    data_selector #(
        .W(W),
        .ADDR_W(ADDR_W)
    ) data_selector_inst (
        .ch(ch),
        .decoded_addr(decoded_addr),
        .out(out)
    );

endmodule

// 地址解码子模块
module addr_decoder #(parameter ADDR_W=2) (
    input [ADDR_W-1:0] addr,
    output [(2**ADDR_W)-1:0] decoded_addr
);
    assign decoded_addr = (1'b1 << addr);
endmodule

// 数据选择子模块
module data_selector #(parameter W=8, ADDR_W=2) (
    input [(2**ADDR_W)-1:0][W-1:0] ch,
    input [(2**ADDR_W)-1:0] decoded_addr,
    output [W-1:0] out
);
    wire [(2**ADDR_W)-1:0][W-1:0] selected_data;
    
    genvar i;
    generate
        for(i=0; i<(2**ADDR_W); i=i+1) begin: gen_sel
            assign selected_data[i] = decoded_addr[i] ? ch[i] : {W{1'b0}};
        end
    endgenerate
    
    assign out = |selected_data;
endmodule