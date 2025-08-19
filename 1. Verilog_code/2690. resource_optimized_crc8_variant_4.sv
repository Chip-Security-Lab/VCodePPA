//SystemVerilog
module resource_optimized_crc8(
    input wire clk,
    input wire rst,
    input wire data_bit,
    input wire valid,
    output wire ready,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'hD5;
    
    wire feedback = crc[7] ^ data_bit;
    reg ready_reg;
    
    // 优化控制逻辑，使用更简洁的状态表示
    localparam RESET_STATE = 2'b00;
    localparam XOR_STATE = 2'b01;
    localparam SHIFT_STATE = 2'b10;
    localparam HOLD_STATE = 2'b11;
    
    reg [1:0] ctrl_state;
    
    // 使用硬件友好的状态逻辑
    always @(*) begin
        case ({rst, valid & ready})
            2'b10, 2'b11: ctrl_state = RESET_STATE;
            2'b01:        ctrl_state = feedback ? XOR_STATE : SHIFT_STATE;
            2'b00:        ctrl_state = HOLD_STATE;
            default:      ctrl_state = HOLD_STATE;
        endcase
    end
    
    // Ready信号生成逻辑 - 减少不必要的寄存器更新
    assign ready = 1'b1; // 模块始终准备好接收数据
    
    // CRC计算逻辑 - 优化多路复用器结构
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc <= 8'h00;
        end else if (valid) begin
            case (ctrl_state)
                XOR_STATE:  crc <= {crc[6:0], 1'b0} ^ POLY;
                SHIFT_STATE: crc <= {crc[6:0], 1'b0};
                default:    crc <= crc;
            endcase
        end
    end
endmodule