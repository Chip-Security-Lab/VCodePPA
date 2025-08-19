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
        detected = 0;
        case (current_state)
            IDLE: if (enable) next_state = CHECKING;
            CHECKING: begin
                detected = (shift_reg == SEQUENCE);
                next_state = CHECKING;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule