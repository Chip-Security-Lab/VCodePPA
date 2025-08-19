//SystemVerilog - IEEE 1364-2005
module sync_decoder(
    input wire clk,
    input wire rst_n,
    input wire [2:0] address,
    output wire [7:0] decode_out
);
    // 内部连线
    wire [7:0] decoded_value;
    
    // 实例化地址解码子模块
    address_decoder addr_dec_inst (
        .address(address),
        .decoded_value(decoded_value)
    );
    
    // 实例化输出寄存器子模块
    output_register out_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(decoded_value),
        .data_out(decode_out)
    );
    
endmodule

//SystemVerilog - IEEE 1364-2005
module address_decoder (
    input wire [2:0] address,
    output wire [7:0] decoded_value
);
    // 纯组合逻辑解码，不需要时钟和复位
    assign decoded_value = (8'b1 << address);
    
endmodule

//SystemVerilog - IEEE 1364-2005
module output_register (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    // 专注于寄存功能，提高了可重用性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else
            data_out <= data_in;
    end
    
endmodule