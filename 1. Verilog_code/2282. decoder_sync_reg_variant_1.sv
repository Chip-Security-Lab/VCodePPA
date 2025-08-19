//SystemVerilog

// 顶层模块
module decoder_sync_reg (
    input wire clk, 
    input wire rst_n, 
    input wire en,
    input wire [3:0] addr,
    output wire [15:0] decoded
);
    // 内部连线
    wire [15:0] decoded_combinational;
    
    // 组合逻辑部分 - 地址解码
    address_decoder addr_decoder_inst (
        .addr(addr),
        .decoded(decoded_combinational)
    );
    
    // 时序逻辑部分 - 输出寄存器
    output_register output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(decoded_combinational),
        .data_out(decoded)
    );
    
endmodule

// 纯组合逻辑解码器子模块
module address_decoder (
    input wire [3:0] addr,
    output wire [15:0] decoded
);
    // 使用assign语句实现组合逻辑
    assign decoded = (1'b1 << addr);
    
endmodule

// 纯时序逻辑输出寄存器子模块
module output_register (
    input wire clk, 
    input wire rst_n, 
    input wire en,
    input wire [15:0] data_in,
    output reg [15:0] data_out
);
    // 时序逻辑部分 - 仅在时钟边沿触发
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'h0000;
        end
        else if (en) begin
            data_out <= data_in;
        end
    end
    
endmodule