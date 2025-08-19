//SystemVerilog IEEE 1364-2005
module pl_reg_parity #(
    parameter W = 8
)(
    input  wire        clk,
    input  wire        load,
    input  wire [W-1:0] data_in,
    output reg  [W:0]   data_out
);

    wire parity_bit;
    
    // 奇偶校验计算子模块
    parity_calculator #(
        .WIDTH(W)
    ) parity_calc_inst (
        .data_in   (data_in),
        .parity_out(parity_bit)
    );
    
    // 数据寄存子模块
    data_register #(
        .WIDTH(W)
    ) data_reg_inst (
        .clk      (clk),
        .load     (load),
        .data_in  (data_in),
        .parity_in(parity_bit),
        .data_out (data_out)
    );
    
endmodule

//SystemVerilog IEEE 1364-2005
module parity_calculator #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_in,
    output wire             parity_out
);

    // 奇偶校验位查找表
    reg [1:0] parity_lut[0:255];
    integer i;
    
    // 初始化查找表
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            parity_lut[i] = ^i;
        end
    end
    
    // 根据数据宽度选择奇偶校验计算方法
    generate
        if (WIDTH == 8) begin: use_lut
            assign parity_out = parity_lut[data_in];
        end else begin: use_xor
            assign parity_out = ^data_in;
        end
    endgenerate
    
endmodule

//SystemVerilog IEEE 1364-2005
module data_register #(
    parameter WIDTH = 8
)(
    input  wire                clk,
    input  wire                load,
    input  wire [WIDTH-1:0]    data_in,
    input  wire                parity_in,
    output reg  [WIDTH:0]      data_out
);

    // 数据和奇偶校验位寄存
    always @(posedge clk) begin
        if (load) begin
            data_out <= {parity_in, data_in};
        end
    end
    
endmodule