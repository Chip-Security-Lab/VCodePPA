//SystemVerilog
module demux_1to4_ifelse (
    input wire din,                   // Data input
    input wire [1:0] select,          // 2-bit selection control
    output reg [3:0] dout             // 4-bit output bus
);

    // Combinational block: Clear all outputs to zero
    // 功能块: 清零输出
    always @(*) begin
        dout = 4'b0000;
    end

    // Combinational block: Set dout[0] based on select and din
    // 功能块: 选择为00时输出
    always @(*) begin
        if (select == 2'b00)
            dout[0] = din;
    end

    // Combinational block: Set dout[1] based on select and din
    // 功能块: 选择为01时输出
    always @(*) begin
        if (select == 2'b01)
            dout[1] = din;
    end

    // Combinational block: Set dout[2] based on select and din
    // 功能块: 选择为10时输出
    always @(*) begin
        if (select == 2'b10)
            dout[2] = din;
    end

    // Combinational block: Set dout[3] based on select and din
    // 功能块: 选择为11时输出
    always @(*) begin
        if (select == 2'b11)
            dout[3] = din;
    end

endmodule