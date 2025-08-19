//SystemVerilog
// Top-level module: mux_convert
// Description: Hierarchical, parameterized multiplexer with enable and tri-state output

module mux_convert #(parameter DW=8, CH=4) (
    input  wire [CH*DW-1:0]    data_in,   // Input data bus (CH channels, DW bits each)
    input  wire [$clog2(CH)-1:0] sel,     // Channel select
    input  wire                en,        // Output enable
    output wire [DW-1:0]       data_out   // Tri-state output
);

    // Internal signal for mux output
    wire [DW-1:0] mux_selected_data;

    // Instantiate multiplexer logic
    mux_convert_mux #(
        .DW(DW),
        .CH(CH)
    ) u_mux (
        .data_in(data_in),
        .sel(sel),
        .data_out(mux_selected_data)
    );

    // Instantiate tri-state output logic
    mux_convert_tristate #(
        .DW(DW)
    ) u_tristate (
        .data_in(mux_selected_data),
        .en(en),
        .data_out(data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_convert_mux
// Description: Parameterized multiplexer. Selects one of CH input words of DW bits.
// -----------------------------------------------------------------------------
module mux_convert_mux #(parameter DW=8, CH=4) (
    input  wire [CH*DW-1:0]        data_in,   // Flat input bus
    input  wire [$clog2(CH)-1:0]   sel,       // Channel select
    output wire [DW-1:0]           data_out   // Selected output
);
    // Extract selected channel using generate for scalability and resource efficiency
    reg [DW-1:0] mux_data;
    integer i;
    always @* begin
        mux_data = {DW{1'b0}};
        for (i = 0; i < CH; i = i + 1) begin
            if (sel == i)
                mux_data = data_in[i*DW +: DW];
        end
    end
    assign data_out = mux_data;
endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_convert_tristate
// Description: Tri-state output logic for mux output with enable control
// -----------------------------------------------------------------------------
module mux_convert_tristate #(parameter DW=8) (
    input  wire [DW-1:0] data_in,   // Data input from mux
    input  wire          en,        // Output enable
    output wire [DW-1:0] data_out   // Tri-state data output
);
    // Tri-state output controlled by enable signal
    assign data_out = en ? data_in : {DW{1'bz}};
endmodule