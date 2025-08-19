//SystemVerilog
module dynamic_xor_mask #(
    parameter WIDTH = 64
)(
    input clk, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] mask_reg;
    reg [WIDTH-1:0] data_in_reg;
    
    // 借位减法器实现的常量值(8位)
    wire [7:0] subtrahend = 8'hB9;
    wire [7:0] current_mask_byte;
    wire [7:0] next_mask_byte;
    wire [8:0] borrow_chain; // 额外的一位用于借位传递
    
    assign current_mask_byte = mask_reg[7:0];
    assign borrow_chain[0] = 1'b0; // 初始无借位
    
    // 8位借位减法器实现
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : borrow_subtractor
            assign next_mask_byte[i] = current_mask_byte[i] ^ subtrahend[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = (~current_mask_byte[i] & subtrahend[i]) | 
                                      (borrow_chain[i] & (~(current_mask_byte[i] ^ subtrahend[i])));
        end
    endgenerate
    
    always @(posedge clk) begin
        if (en) begin
            // 寄存器输入数据，减少输入到第一级寄存器的延迟
            data_in_reg <= data_in;
            
            // 更新掩码寄存器 - 使用借位减法器替代原来的XOR操作
            mask_reg <= {mask_reg[WIDTH-1:8], next_mask_byte};
            
            // 将XOR操作应用到已寄存的数据上
            data_out <= data_in_reg ^ mask_reg;
        end
    end
endmodule