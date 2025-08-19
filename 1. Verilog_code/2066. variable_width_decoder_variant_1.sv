//SystemVerilog
module variable_width_decoder #(
    parameter IN_WIDTH = 3,
    parameter OUT_SEL = 2
) (
    input wire [IN_WIDTH-1:0] encoded_in,
    input wire [OUT_SEL-1:0] width_sel,
    output reg [(2**IN_WIDTH)-1:0] decoded_out
);
    reg [(2**IN_WIDTH)-1:0] decoded_next;
    reg [4:0] sel_index;
    integer idx;

    always @(*) begin
        // Calculate sel_index efficiently based on width_sel
        case (width_sel)
            2'd0: sel_index = {4'b0000, encoded_in[0]};
            2'd1: sel_index = {3'b000, encoded_in[1:0]};
            2'd2: sel_index = {2'b00, encoded_in[2:0]};
            2'd3: sel_index = { {5-IN_WIDTH{1'b0}}, encoded_in[IN_WIDTH-1:0]};
            default: sel_index = 5'b00000;
        endcase

        // Efficient one-hot decoding using direct comparison
        decoded_next = {(2**IN_WIDTH){1'b0}};
        if (sel_index < (2**IN_WIDTH)) begin
            decoded_next[sel_index] = 1'b1;
        end
        decoded_out = decoded_next;
    end
endmodule