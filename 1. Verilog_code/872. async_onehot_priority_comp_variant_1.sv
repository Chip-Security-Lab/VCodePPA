//SystemVerilog
module async_onehot_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] priority_onehot,
    output valid
);
    // 优化的高性能一热优先级编码器
    wire [WIDTH:0] higher_priority_present;
    
    // 任何更高位有输入的指示信号
    assign higher_priority_present[WIDTH] = 1'b0;
    
    genvar i;
    generate
        for (i = WIDTH-1; i >= 0; i = i - 1) begin : priority_chain
            assign higher_priority_present[i] = higher_priority_present[i+1] | data_in[i];
            assign priority_onehot[i] = data_in[i] & ~higher_priority_present[i+1];
        end
    endgenerate
    
    assign valid = higher_priority_present[0];
endmodule