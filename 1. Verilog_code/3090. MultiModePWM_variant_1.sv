//SystemVerilog
module MultiModePWM #(
    parameter RESOLUTION = 10
)(
    input clk, rst_n,
    input [1:0] mode,
    input [RESOLUTION-1:0] duty_cycle,
    output reg pwm_out
);
    reg [RESOLUTION-1:0] counter;
    reg [RESOLUTION-1:0] phase;

    // 模式解码
    localparam 
        MODE_NORMAL = 2'b00,
        MODE_PHASE_SHIFT = 2'b01,
        MODE_CENTER_ALIGN = 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            phase <= 0;
        end else begin
            counter <= counter + 1;
            case(mode)
                MODE_PHASE_SHIFT: phase <= duty_cycle >> 1;
                MODE_CENTER_ALIGN: phase <= (2**RESOLUTION - duty_cycle) >> 1;
                default: phase <= 0;
            endcase
        end
    end

    always @(*) begin
        case(mode)
            MODE_NORMAL: 
                pwm_out = (counter < duty_cycle);
            MODE_PHASE_SHIFT:
                pwm_out = ((counter + phase) % (2**RESOLUTION)) < duty_cycle;
            MODE_CENTER_ALIGN:
                pwm_out = (counter >= phase) && (counter < (phase + duty_cycle));
            default: pwm_out = 0;
        endcase
    end
endmodule
