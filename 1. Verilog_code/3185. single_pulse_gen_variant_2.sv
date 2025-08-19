//SystemVerilog
module single_pulse_gen #(
    parameter DELAY_CYCLES = 50
)(
    input clk,
    input trigger,
    output reg pulse
);
    reg [31:0] counter;
    reg state;
    wire [31:0] counter_next;
    wire borrow;

    // 条件求和减法算法实现
    assign {borrow, counter_next} = {1'b0, counter} + {1'b0, 32'hFFFFFFFF} + 1'b1; // counter - 1 使用补码加法实现

    always @(posedge clk) begin
        case(state)
            1'b0: begin
                if (trigger) begin
                    counter <= DELAY_CYCLES;
                    state <= 1'b1;
                end
            end
            1'b1: begin
                if (counter > 0) begin
                    counter <= counter_next;
                    pulse <= (counter == 1);
                    if (counter == 1) begin
                        state <= 1'b0;
                    end else begin
                        state <= 1'b1;
                    end
                end
            end
            default: begin
                state <= 1'b0;
                pulse <= 1'b0;
                counter <= 32'd0;
            end
        endcase
    end
endmodule