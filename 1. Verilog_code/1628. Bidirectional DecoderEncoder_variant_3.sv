//SystemVerilog
module bidir_decoder (
    input decode_mode,
    input [2:0] addr_in,
    input [7:0] onehot_in,
    output reg [2:0] addr_out,
    output reg [7:0] onehot_out,
    output reg error
);

    // Barrel shifter implementation for decoder mode
    always @(*) begin
        if (decode_mode) begin
            case (addr_in)
                3'd0: onehot_out = 8'b00000001;
                3'd1: onehot_out = 8'b00000010;
                3'd2: onehot_out = 8'b00000100;
                3'd3: onehot_out = 8'b00001000;
                3'd4: onehot_out = 8'b00010000;
                3'd5: onehot_out = 8'b00100000;
                3'd6: onehot_out = 8'b01000000;
                3'd7: onehot_out = 8'b10000000;
                default: onehot_out = 8'b00000000;
            endcase
        end else begin
            onehot_out = 8'b00000000;
        end
    end

    // Encoder mode logic with optimized error detection
    always @(*) begin
        if (!decode_mode) begin
            addr_out = 3'b000;
            error = 1'b1;
            
            case (onehot_in)
                8'b00000001: begin addr_out = 3'd0; error = 1'b0; end
                8'b00000010: begin addr_out = 3'd1; error = 1'b0; end
                8'b00000100: begin addr_out = 3'd2; error = 1'b0; end
                8'b00001000: begin addr_out = 3'd3; error = 1'b0; end
                8'b00010000: begin addr_out = 3'd4; error = 1'b0; end
                8'b00100000: begin addr_out = 3'd5; error = 1'b0; end
                8'b01000000: begin addr_out = 3'd6; error = 1'b0; end
                8'b10000000: begin addr_out = 3'd7; error = 1'b0; end
                default: begin addr_out = 3'd0; error = 1'b1; end
            endcase
        end else begin
            addr_out = 3'b000;
            error = 1'b0;
        end
    end

endmodule