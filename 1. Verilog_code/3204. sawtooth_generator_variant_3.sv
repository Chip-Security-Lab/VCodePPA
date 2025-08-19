//SystemVerilog
module sawtooth_generator(
    input clock,
    input areset,
    input en,
    output reg [7:0] sawtooth
);
    // Simplified state encoding using one-hot encoding for better timing
    reg [2:0] state;
    localparam RESET = 3'b001;
    localparam COUNT = 3'b010;
    localparam HOLD = 3'b100;
    
    // Counter logic with optimized implementation
    wire count_en = (state == COUNT) & en;
    wire hold_to_count = (state == HOLD) & en;
    wire next_state_count = count_en | hold_to_count;
    
    // State transition logic
    always @(posedge clock or posedge areset) begin
        if (areset) begin
            state <= RESET;
        end else begin
            case (state)
                RESET: state <= COUNT;
                COUNT: state <= en ? COUNT : HOLD;
                HOLD: state <= en ? COUNT : HOLD;
                default: state <= RESET;
            endcase
        end
    end
    
    // Sawtooth counter with optimized implementation
    always @(posedge clock or posedge areset) begin
        if (areset) begin
            sawtooth <= 8'h00;
        end else if (next_state_count) begin
            sawtooth <= sawtooth + 8'h01;
        end
    end
endmodule