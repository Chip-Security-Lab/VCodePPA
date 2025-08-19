module midi_encoder (
    input clk, note_on,
    input [6:0] note, velocity,
    output reg [7:0] tx_byte
);
    reg [1:0] state;
    always @(posedge clk) begin
        case(state)
            0: if(note_on) begin
                tx_byte <= 8'h90;
                state <= 1;
            end
            1: begin
                tx_byte <= note;
                state <= 2;
            end
            2: begin
                tx_byte <= velocity;
                state <= 0;
            end
        endcase
    end
endmodule