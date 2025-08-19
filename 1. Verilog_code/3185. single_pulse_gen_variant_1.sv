//SystemVerilog
module single_pulse_gen #(
    parameter DELAY_CYCLES = 50
)(
    input clk,
    input trigger,
    output reg pulse
);
    localparam IDLE = 1'b0;
    localparam COUNTING = 1'b1;
    
    reg [31:0] counter;
    reg state;
    
    always @(posedge clk) begin
        pulse <= 1'b0; // Default value, only set high when needed
        
        case(state)
            IDLE: begin
                if (trigger) begin
                    counter <= DELAY_CYCLES;
                    state <= COUNTING;
                end
            end
            
            COUNTING: begin
                if (counter == 1) begin
                    pulse <= 1'b1;
                    state <= IDLE;
                end else if (counter > 0) begin
                    counter <= counter - 1;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
endmodule