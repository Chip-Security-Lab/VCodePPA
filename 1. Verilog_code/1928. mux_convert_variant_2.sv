//SystemVerilog
// Top-level module: mux_convert_top
// Function: Hierarchically selects a channel from data_in based on sel and en signals.

module mux_convert_top #(parameter DW=8, CH=4) (
    input  [CH*DW-1:0] data_in,
    input  [$clog2(CH)-1:0] sel,
    input  en,
    output [DW-1:0] data_out
);

    // Internal signal for selected channel
    wire [DW-1:0] selected_channel;
    // Internal signal for output enable logic
    wire [DW-1:0] enabled_output;

    // Instantiate channel selection submodule
    mux_channel_selector #(.DW(DW), .CH(CH)) u_channel_selector (
        .data_in        (data_in),
        .sel            (sel),
        .data_selected  (selected_channel)
    );

    // Instantiate output enable submodule
    mux_output_enable #(.DW(DW)) u_output_enable (
        .data_in    (selected_channel),
        .en         (en),
        .data_out   (enabled_output)
    );

    assign data_out = enabled_output;

endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_channel_selector
// Function: Selects a channel from the flattened data_in bus based on sel
// -----------------------------------------------------------------------------
module mux_channel_selector #(parameter DW=8, CH=4) (
    input  [CH*DW-1:0] data_in,
    input  [$clog2(CH)-1:0] sel,
    output [DW-1:0] data_selected
);
    // Internal signal for decoded channel
    reg [DW-1:0] channel_data;

    integer i;
    always @* begin
        channel_data = {DW{1'b0}};
        for (i = 0; i < CH; i = i + 1) begin
            if (sel == i[$clog2(CH)-1:0]) begin
                channel_data = data_in[i*DW +: DW];
            end
        end
    end

    assign data_selected = channel_data;
endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_output_enable
// Function: Drives data_out with data_in if en is high, otherwise drives zeros
// -----------------------------------------------------------------------------
module mux_output_enable #(parameter DW=8) (
    input  [DW-1:0] data_in,
    input  en,
    output [DW-1:0] data_out
);
    // Internal signal for output logic
    reg [DW-1:0] out_data;

    always @* begin
        if (en)
            out_data = data_in;
        else
            out_data = {DW{1'b0}};
    end

    assign data_out = out_data;
endmodule