//SystemVerilog
module init_value_crc8(
    input wire clock,
    input wire resetn,
    input wire [7:0] init_value,
    input wire init_load,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] crc_out
);
    parameter [7:0] POLYNOMIAL = 8'hD5;
    reg [7:0] next_crc;
    
    // 优化组合逻辑，减少多路选择器深度
    always @(*) begin
        // 默认保持当前值
        next_crc = crc_out;
        
        if (data_valid && !init_load) begin
            // 优化XOR条件判断，直接计算结果
            next_crc = {crc_out[6:0], 1'b0};
            next_crc = next_crc ^ ({8{crc_out[7] ^ data[0]}} & POLYNOMIAL);
        end else if (init_load) begin
            // 加载初始值优先级高于数据处理
            next_crc = init_value;
        end
    end
    
    // 简化时序逻辑
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            crc_out <= 8'h00;
        end else begin
            crc_out <= next_crc;
        end
    end
endmodule