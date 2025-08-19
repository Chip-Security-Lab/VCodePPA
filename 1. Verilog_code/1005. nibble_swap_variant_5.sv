//SystemVerilog
// Top-level module: nibble_swap_vr_vr
// Function: Swaps nibbles of a 16-bit word if swap_enable is asserted using Valid-Ready handshake
module nibble_swap_vr_vr(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [15:0]  data_in,
    input  wire         swap_enable,
    input  wire         in_valid,
    output wire         in_ready,
    output wire [15:0]  data_out,
    output wire         out_valid,
    input  wire         out_ready
);

    reg         input_accepted;
    reg  [15:0] data_in_reg;
    reg         swap_enable_reg;
    wire [15:0] swapped_data;
    reg  [15:0] muxed_data;
    reg         out_valid_reg;
    reg         in_ready_reg;
    reg  [15:0] data_out_reg;

    // Input handshake: accept data only when both valid and ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_accepted    <= 1'b0;
            data_in_reg       <= 16'd0;
            swap_enable_reg   <= 1'b0;
        end else if (in_valid && in_ready) begin
            input_accepted    <= 1'b1;
            data_in_reg       <= data_in;
            swap_enable_reg   <= swap_enable;
        end else if (out_valid_reg && out_ready) begin
            input_accepted    <= 1'b0;
        end
    end

    // Ready to accept new data if not holding valid output data
    always @(*) begin
        in_ready_reg = ~input_accepted || (out_valid_reg && out_ready);
    end

    assign in_ready = in_ready_reg;

    // Submodule: Performs the nibble swapping operation
    nibble_swapper u_nibble_swapper (
        .data_in   (data_in_reg),
        .swapped   (swapped_data)
    );

    // Submodule: Selects between original and swapped data based on swap_enable
    nibble_swap_mux u_nibble_swap_mux (
        .original  (data_in_reg),
        .swapped   (swapped_data),
        .swap_en   (swap_enable_reg),
        .data_out  (muxed_data)
    );

    // Output handshake: output valid when data is accepted, clear when downstream ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid_reg <= 1'b0;
        end else if (input_accepted && !out_valid_reg) begin
            out_valid_reg <= 1'b1;
        end else if (out_valid_reg && out_ready) begin
            out_valid_reg <= 1'b0;
        end
    end

    // Output data register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 16'd0;
        end else if (input_accepted && !out_valid_reg) begin
            data_out_reg <= muxed_data;
        end
    end

    assign data_out  = data_out_reg;
    assign out_valid = out_valid_reg;

endmodule

// -----------------------------------------------------------------------------
// nibble_swapper
// Swaps the four nibbles of a 16-bit input: [D3|D2|D1|D0] -> [D0|D1|D2|D3]
module nibble_swapper(
    input  wire [15:0] data_in,
    output wire [15:0] swapped
);
    assign swapped = {data_in[3:0], data_in[7:4], data_in[11:8], data_in[15:12]};
endmodule

// -----------------------------------------------------------------------------
// nibble_swap_mux
// Selects between original and swapped data based on swap_en
module nibble_swap_mux(
    input  wire [15:0] original,
    input  wire [15:0] swapped,
    input  wire        swap_en,
    output wire [15:0] data_out
);
    assign data_out = swap_en ? swapped : original;
endmodule