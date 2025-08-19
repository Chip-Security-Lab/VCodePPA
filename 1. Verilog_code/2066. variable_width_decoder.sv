module variable_width_decoder #(
    parameter IN_WIDTH = 3,
    parameter OUT_SEL = 2
) (
    input wire [IN_WIDTH-1:0] encoded_in,
    input wire [OUT_SEL-1:0] width_sel,
    output reg [(2**IN_WIDTH)-1:0] decoded_out
);
    wire [4:0] output_width;
    assign output_width = 1 << width_sel;
    
    always @(*) begin
        decoded_out = {(2**IN_WIDTH){1'b0}};
        case (width_sel)
            2'd0: decoded_out[encoded_in[0:0]] = 1'b1;      // 2-way decode
            2'd1: decoded_out[encoded_in[1:0]] = 1'b1;      // 4-way decode
            2'd2: decoded_out[encoded_in[2:0]] = 1'b1;      // 8-way decode
            2'd3: decoded_out[encoded_in[IN_WIDTH-1:0]] = 1'b1; // Full-width decode
        endcase
    end
endmodule