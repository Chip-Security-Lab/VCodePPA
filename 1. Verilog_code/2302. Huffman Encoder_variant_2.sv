//SystemVerilog
module huffman_encoder (
    input [7:0] symbol_in,
    input       req_in,
    output reg [15:0] code_out,
    output reg [3:0]  code_len,
    output      ack_out
);
    // 中间信号定义优化
    reg [15:0] symbol_code;
    reg [3:0]  symbol_len;
    
    // 将握手信号简化为组合逻辑
    assign ack_out = req_in;
    
    // 简化编码和长度确定逻辑
    always @(*) begin
        // 默认值设置
        symbol_code = 16'b111110;
        symbol_len = 4'd6;
        
        case (symbol_in)
            8'h41: begin symbol_code = 16'b0;     symbol_len = 4'd1; end  // 'A'
            8'h42: begin symbol_code = 16'b10;    symbol_len = 4'd2; end  // 'B'
            8'h43: begin symbol_code = 16'b110;   symbol_len = 4'd3; end  // 'C'
            8'h44: begin symbol_code = 16'b1110;  symbol_len = 4'd4; end  // 'D'
            8'h45: begin symbol_code = 16'b11110; symbol_len = 4'd5; end  // 'E'
        endcase
    end
    
    // 输出逻辑优化
    always @(*) begin
        if (req_in) begin
            code_out = symbol_code;
            code_len = symbol_len;
        end else begin
            code_out = 16'b0;
            code_len = 4'd0;
        end
    end
endmodule