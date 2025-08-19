//SystemVerilog
module SequenceDetector #(
    parameter DATA_WIDTH = 8,
    parameter SEQUENCE = 8'b1010_1010
)(
    input clk, rst_n,
    input data_in,
    input enable,
    output reg detected
);
    // 使用localparam代替typedef enum
    localparam IDLE = 1'b0, CHECKING = 1'b1;
    reg current_state, next_state;
    reg [DATA_WIDTH-1:0] shift_reg;
    
    // 先行借位减法器信号
    wire [DATA_WIDTH-1:0] difference;
    wire [DATA_WIDTH:0] borrow;
    
    // 生成先行借位信号
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for(i = 0; i < DATA_WIDTH; i = i + 1) begin: gen_borrow
            assign borrow[i+1] = (~shift_reg[i] & SEQUENCE[i]) | 
                                 ((~shift_reg[i] | SEQUENCE[i]) & borrow[i]);
            assign difference[i] = shift_reg[i] ^ SEQUENCE[i] ^ borrow[i];
        end
    endgenerate
    
    // 检测是否匹配 - 如果差值为0则匹配
    wire is_match;
    assign is_match = (difference == 8'b0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            shift_reg <= 0;
        end else if (enable) begin
            current_state <= next_state;
            // 每个时钟周期移入一位
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], data_in};
        end
    end

    always @(*) begin
        next_state = current_state;
        detected = 1'b0;
        case (current_state)
            IDLE: if (enable) next_state = CHECKING;
            CHECKING: begin
                detected = is_match;
                next_state = CHECKING;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule