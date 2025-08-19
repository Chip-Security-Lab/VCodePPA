//SystemVerilog
module level_pulse_gen(
    input clock,
    input trigger,
    input [3:0] pulse_width,
    output reg pulse
);
    reg [3:0] counter;
    reg triggered;
    
    // 定义状态编码
    reg [1:0] state;
    localparam IDLE = 2'b00,
               PULSE_ON = 2'b01,
               PULSE_OFF = 2'b10;
    
    always @(posedge clock) begin
        case (state)
            IDLE: begin
                if (trigger && !triggered) begin
                    triggered <= 1'b1;
                    counter <= 4'd0;
                    pulse <= 1'b1;
                    state <= PULSE_ON;
                end
            end
            
            PULSE_ON: begin
                if (counter == pulse_width - 1) begin
                    pulse <= 1'b0;
                    triggered <= 1'b0;
                    state <= IDLE;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
endmodule