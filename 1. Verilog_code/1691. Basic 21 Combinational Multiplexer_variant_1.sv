//SystemVerilog
module basic_mux_2to1(
    input [7:0] data0, data1,
    input sel,
    output [7:0] out
);

    // 实例化选择逻辑子模块
    mux_selector selector(
        .data0(data0),
        .data1(data1),
        .sel(sel),
        .out(out)
    );

endmodule

// 选择逻辑子模块
module mux_selector(
    input [7:0] data0, data1,
    input sel,
    output reg [7:0] out
);

    always @(*) begin
        if (sel) begin
            out = data1;
        end else begin
            out = data0;
        end
    end

endmodule