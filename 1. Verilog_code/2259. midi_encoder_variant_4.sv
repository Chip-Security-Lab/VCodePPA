//SystemVerilog
//IEEE 1364-2005 Verilog standard
module midi_encoder (
    input wire clk,
    input wire note_on,
    input wire [6:0] note,
    input wire [6:0] velocity,
    output reg [7:0] tx_byte
);
    // Use localparam for better readability and maintainability
    localparam STATE_IDLE = 2'b00;
    localparam STATE_NOTE = 2'b01;
    localparam STATE_VELOCITY = 2'b10;
    
    // State registers
    reg [1:0] state;
    
    // Internal combinational signals
    wire [1:0] next_state;
    wire [7:0] next_tx_byte;
    
    // Instantiate combinational logic module
    midi_encoder_comb comb_logic (
        .state(state),
        .note_on(note_on),
        .note(note),
        .velocity(velocity),
        .next_state(next_state),
        .next_tx_byte(next_tx_byte)
    );
    
    // Sequential logic block
    always @(posedge clk) begin
        state <= next_state;
        tx_byte <= next_tx_byte;
    end
    
endmodule

// Separate module for combinational logic
module midi_encoder_comb (
    input wire [1:0] state,
    input wire note_on,
    input wire [6:0] note,
    input wire [6:0] velocity,
    output reg [1:0] next_state,
    output reg [7:0] next_tx_byte
);
    // State definitions
    localparam STATE_IDLE = 2'b00;
    localparam STATE_NOTE = 2'b01;
    localparam STATE_VELOCITY = 2'b10;
    
    // Next state logic
    always @(*) begin
        next_state = state;
        case(state)
            STATE_IDLE: 
                if(note_on) next_state = STATE_NOTE;
            STATE_NOTE: 
                next_state = STATE_VELOCITY;
            STATE_VELOCITY: 
                next_state = STATE_IDLE;
            default: 
                next_state = STATE_IDLE;
        endcase
    end
    
    // Output logic
    always @(*) begin
        // Default: maintain current output
        next_tx_byte = 8'h00; // Default value to avoid latches
        
        case(state)
            STATE_IDLE: 
                if(note_on) next_tx_byte = 8'h90;
            STATE_NOTE: 
                next_tx_byte = {1'b0, note};
            STATE_VELOCITY: 
                next_tx_byte = {1'b0, velocity};
            default: 
                next_tx_byte = 8'h00;
        endcase
    end
    
endmodule