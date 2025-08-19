//SystemVerilog
// 顶层模块：波形多路选择顶层
module wave20_combo(
    input  wire [1:0] sel,
    input  wire [7:0] in_sin,
    input  wire [7:0] in_tri,
    input  wire [7:0] in_saw,
    output wire [7:0] wave_out
);

    wire [7:0] mux_out;

    // 实例化波形多路选择子模块
    wave_selector #(
        .DATA_WIDTH(8)
    ) u_wave_selector (
        .sel        (sel),
        .sin_wave   (in_sin),
        .tri_wave   (in_tri),
        .saw_wave   (in_saw),
        .out_wave   (mux_out)
    );

    assign wave_out = mux_out;

endmodule

// 子模块：波形多路选择器
// 功能：根据选择信号sel输出对应的波形数据
module wave_selector #(
    parameter DATA_WIDTH = 8
)(
    input  wire [1:0] sel,
    input  wire [DATA_WIDTH-1:0] sin_wave,
    input  wire [DATA_WIDTH-1:0] tri_wave,
    input  wire [DATA_WIDTH-1:0] saw_wave,
    output wire [DATA_WIDTH-1:0] out_wave
);
    reg [DATA_WIDTH-1:0] wave_mux_reg;

    always @(*) begin
        if (sel == 2'b00) begin
            wave_mux_reg = sin_wave;
        end else if (sel == 2'b01) begin
            wave_mux_reg = tri_wave;
        end else if (sel == 2'b10) begin
            wave_mux_reg = saw_wave;
        end else begin
            wave_mux_reg = {DATA_WIDTH{1'b0}};
        end
    end

    assign out_wave = wave_mux_reg;
endmodule