module fsm_reset_sequencer(
    input wire clk,
    input wire trigger,
    output reg [3:0] reset_signals
);
    reg [1:0] state, next_state;
    always @(posedge clk) begin
        if (trigger) begin
            state <= 2'b00;
            reset_signals <= 4'b1111;
        end else begin
            case (state)
                2'b00: begin state <= 2'b01; reset_signals <= 4'b0111; end
                2'b01: begin state <= 2'b10; reset_signals <= 4'b0011; end
                2'b10: begin state <= 2'b11; reset_signals <= 4'b0001; end
                2'b11: begin state <= 2'b11; reset_signals <= 4'b0000; end
            endcase
        end
    end
endmodule