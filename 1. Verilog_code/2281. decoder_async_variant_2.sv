//SystemVerilog
module decoder_async #(parameter AW=4, DW=16) (
    input [AW-1:0] addr,
    output reg [DW-1:0] decoded
);
    wire comparison_result;
    wire [AW:0] extended_addr;
    wire [AW:0] extended_dw;
    wire [AW:0] diff;
    wire [AW:0] addr_comp;
    
    // 扩展一位防止溢出
    assign extended_addr = {1'b0, addr};
    assign extended_dw = {1'b0, DW[AW-1:0]}; 
    
    // 计算addr的二进制补码
    assign addr_comp = ~extended_addr + 1'b1;
    
    // 进行DW + addr的二进制补码 = DW - addr
    assign diff = extended_dw + addr_comp;
    
    // 检查结果符号位，如果为1表示addr < DW
    assign comparison_result = diff[AW];
    
    // 使用if-else结构替代条件运算符
    always @(*) begin
        if (comparison_result) begin
            decoded = {DW{1'b0}};
            decoded[addr] = 1'b1;
        end
        else begin
            decoded = {DW{1'b0}};
        end
    end
endmodule