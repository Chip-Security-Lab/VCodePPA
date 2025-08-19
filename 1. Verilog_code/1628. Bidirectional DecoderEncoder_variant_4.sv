//SystemVerilog
module bidir_decoder (
    input decode_mode,
    input [2:0] addr_in,
    input [7:0] onehot_in,
    output reg [2:0] addr_out,
    output reg [7:0] onehot_out,
    output reg error
);

    always @(*) begin
        error = 1'b0;
        addr_out = 3'b000;
        onehot_out = 8'b00000000;
        
        if (decode_mode) begin
            // Decoder mode - optimized using direct bit shift
            onehot_out = (8'b00000001 << addr_in);
        end else begin
            // Encoder mode - optimized using priority encoder
            casez (onehot_in)
                8'b00000001: begin addr_out = 3'd0; error = 1'b0; end
                8'b00000010: begin addr_out = 3'd1; error = 1'b0; end
                8'b00000100: begin addr_out = 3'd2; error = 1'b0; end
                8'b00001000: begin addr_out = 3'd3; error = 1'b0; end
                8'b00010000: begin addr_out = 3'd4; error = 1'b0; end
                8'b00100000: begin addr_out = 3'd5; error = 1'b0; end
                8'b01000000: begin addr_out = 3'd6; error = 1'b0; end
                8'b10000000: begin addr_out = 3'd7; error = 1'b0; end
                default: error = 1'b1;
            endcase
        end
    end
endmodule