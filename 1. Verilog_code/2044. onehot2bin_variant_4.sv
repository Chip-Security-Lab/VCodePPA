//SystemVerilog
module onehot2bin #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3
)(
    input wire [OH_WIDTH-1:0] onehot_in,
    output reg [OUT_WIDTH-1:0] bin_out
);

    always @(*) begin
        case (onehot_in)
            8'b00000001: bin_out = 3'd0;
            8'b00000010: bin_out = 3'd1;
            8'b00000100: bin_out = 3'd2;
            8'b00001000: bin_out = 3'd3;
            8'b00010000: bin_out = 3'd4;
            8'b00100000: bin_out = 3'd5;
            8'b01000000: bin_out = 3'd6;
            8'b10000000: bin_out = 3'd7;
            default: begin
                // Handle don't-care and multiple/higher values
                if ((onehot_in & ~(8'b00000001)) == 8'b0 && onehot_in[0]) begin
                    bin_out = 3'd0;
                end else if ((onehot_in & ~(8'b00000010)) == 8'b0 && onehot_in[1]) begin
                    bin_out = 3'd1;
                end else if ((onehot_in & ~(8'b00000100)) == 8'b0 && onehot_in[2]) begin
                    bin_out = 3'd2;
                end else if ((onehot_in & ~(8'b00001000)) == 8'b0 && onehot_in[3]) begin
                    bin_out = 3'd3;
                end else if ((onehot_in & ~(8'b00010000)) == 8'b0 && onehot_in[4]) begin
                    bin_out = 3'd4;
                end else if ((onehot_in & ~(8'b00100000)) == 8'b0 && onehot_in[5]) begin
                    bin_out = 3'd5;
                end else if ((onehot_in & ~(8'b01000000)) == 8'b0 && onehot_in[6]) begin
                    bin_out = 3'd6;
                end else if ((onehot_in & ~(8'b10000000)) == 8'b0 && onehot_in[7]) begin
                    bin_out = 3'd7;
                end else begin
                    bin_out = {OUT_WIDTH{1'b0}};
                end
            end
        endcase
    end

endmodule