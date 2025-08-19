//SystemVerilog
module basic_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] crc_out
);
    parameter POLY = 8'hD5; // x^8 + x^7 + x^6 + x^4 + x^2 + 1
    
    // 状态编码
    localparam IDLE  = 1'b0;
    localparam CALC  = 1'b1;
    
    reg state, next_state;
    reg [7:0] next_crc;
    
    // 优化的CRC计算逻辑，使用表格查找方法
    reg [7:0] crc_table [0:255];
    integer i, j;
    
    // 计算CRC表
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            crc_table[i] = i;
            for (j = 0; j < 8; j = j + 1) begin
                if (crc_table[i][7])
                    crc_table[i] = (crc_table[i] << 1) ^ POLY;
                else
                    crc_table[i] = (crc_table[i] << 1);
            end
        end
    end
    
    // 状态转移逻辑
    always @(*) begin
        next_state = state;
        
        case(state)
            IDLE: if (data_valid) next_state = CALC;
            CALC: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // CRC计算逻辑
    always @(*) begin
        next_crc = crc_out;
        
        if (state == CALC) begin
            // 使用查表法，减少计算延迟
            next_crc = crc_table[crc_out ^ data_in];
        end
    end
    
    // 状态和输出更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            crc_out <= 8'h00;
        end else begin
            state <= next_state;
            if (state == CALC) begin
                crc_out <= next_crc;
            end
        end
    end
endmodule