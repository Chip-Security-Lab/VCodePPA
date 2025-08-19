//SystemVerilog
module invert_decoder #(
    parameter INVERT_OUTPUT = 0
)(
    input  wire [2:0] bin_addr,
    output wire [7:0] dec_out
);

    // Pipeline stage 1: Address decoding
    reg [7:0] decoded_value;
    always @(*) begin
        case(bin_addr)
            3'd0: decoded_value = 8'b00000001;
            3'd1: decoded_value = 8'b00000010;
            3'd2: decoded_value = 8'b00000100;
            3'd3: decoded_value = 8'b00001000;
            3'd4: decoded_value = 8'b00010000;
            3'd5: decoded_value = 8'b00100000;
            3'd6: decoded_value = 8'b01000000;
            3'd7: decoded_value = 8'b10000000;
            default: decoded_value = 8'b00000000;
        endcase
    end

    // Pipeline stage 2: Output inversion control
    reg [7:0] final_output;
    always @(*) begin
        if (INVERT_OUTPUT) begin
            final_output = ~decoded_value;
        end else begin
            final_output = decoded_value;
        end
    end

    assign dec_out = final_output;

endmodule