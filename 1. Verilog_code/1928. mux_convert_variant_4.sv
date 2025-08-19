//SystemVerilog
module mux_convert #(parameter DW=8, CH=4) (
    input  [CH*DW-1:0] data_in,
    input  [$clog2(CH)-1:0] sel,
    input  en,
    output reg [DW-1:0] data_out
);

    // Internal signals for shift-add multiplication
    reg [DW-1:0] selected_data;
    reg [DW-1:0] shift_add_result;
    integer bit_idx;
    reg [DW-1:0] multiplicand;
    reg [DW-1:0] multiplier;
    reg [2*DW-1:0] partial_sum;

    // Data selection using multiplexer
    always @* begin : mux_select
        case (sel)
            0: selected_data = data_in[DW-1:0];
            1: selected_data = data_in[2*DW-1:DW];
            2: selected_data = data_in[3*DW-1:2*DW];
            3: selected_data = data_in[4*DW-1:3*DW];
            default: selected_data = {DW{1'b0}};
        endcase
    end

    // Example operands for multiplication (for demonstration: selected_data * en)
    // Replace en with an 8-bit multiplicand if needed.
    always @* begin : shift_add_multiplier
        multiplicand = selected_data;
        multiplier = {7'b0, en}; // Zero-extend en to 8 bits
        partial_sum = 0;
        for (bit_idx = 0; bit_idx < DW; bit_idx = bit_idx + 1) begin
            if (multiplier[bit_idx])
                partial_sum = partial_sum + (multiplicand << bit_idx);
        end
        shift_add_result = partial_sum[DW-1:0];
    end

    // Output assignment
    always @* begin : output_logic
        if (en)
            data_out = shift_add_result;
        else
            data_out = {DW{1'bz}};
    end

endmodule