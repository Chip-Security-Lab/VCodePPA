//SystemVerilog
// Top-level module: reset_history_tracker
module reset_history_tracker(
    input  wire        clk,
    input  wire        clear_history,
    input  wire        por_n,
    input  wire        wdt_n,
    input  wire        soft_n,
    input  wire        ext_n,
    output wire [3:0]  current_rst_src,
    output wire [15:0] reset_history
);

    // Internal signals for inter-module connections
    wire [3:0] rst_sources;
    wire [3:0] prev_rst_sources;
    wire       rst_detected;

    // Submodule: reset_source_decoder
    // Decodes active-low reset sources into a 4-bit active-high vector
    reset_source_decoder u_reset_source_decoder (
        .por_n      (por_n),
        .wdt_n      (wdt_n),
        .soft_n     (soft_n),
        .ext_n      (ext_n),
        .rst_sources(rst_sources)
    );

    // Submodule: reset_edge_detector
    // Registers previous reset sources and detects any rising edge
    reset_edge_detector u_reset_edge_detector (
        .clk              (clk),
        .rst_sources      (rst_sources),
        .prev_rst_sources (prev_rst_sources),
        .edge_detected    (rst_detected)
    );

    // Submodule: reset_history_register
    // Maintains and updates the reset history register
    reset_history_register u_reset_history_register (
        .clk              (clk),
        .clear_history    (clear_history),
        .rst_sources      (rst_sources),
        .prev_rst_sources (prev_rst_sources),
        .edge_detected    (rst_detected),
        .current_rst_src  (current_rst_src),
        .reset_history    (reset_history)
    );

endmodule

// --------------------------------------------------------------------------
// Submodule: reset_source_decoder
// Description: Decodes four active-low reset inputs into a 4-bit vector
// --------------------------------------------------------------------------
module reset_source_decoder(
    input  wire por_n,
    input  wire wdt_n,
    input  wire soft_n,
    input  wire ext_n,
    output wire [3:0] rst_sources
);
    assign rst_sources = {~ext_n, ~soft_n, ~wdt_n, ~por_n};
endmodule

// --------------------------------------------------------------------------
// Submodule: reset_edge_detector
// Description: Registers previous reset sources and detects any rising edge
// --------------------------------------------------------------------------
module reset_edge_detector(
    input  wire        clk,
    input  wire [3:0]  rst_sources,
    output reg  [3:0]  prev_rst_sources,
    output wire        edge_detected
);
    always @(posedge clk) begin
        prev_rst_sources <= rst_sources;
    end

    assign edge_detected = | (rst_sources & ~prev_rst_sources);

endmodule

// --------------------------------------------------------------------------
// Submodule: reset_history_register
// Description: Maintains and updates the reset history register and current source
// --------------------------------------------------------------------------
module reset_history_register(
    input  wire        clk,
    input  wire        clear_history,
    input  wire [3:0]  rst_sources,
    input  wire [3:0]  prev_rst_sources,
    input  wire        edge_detected,
    output reg  [3:0]  current_rst_src,
    output reg  [15:0] reset_history
);
    always @(posedge clk) begin
        current_rst_src <= rst_sources;
        if (clear_history) begin
            reset_history <= 16'h0000;
        end else if (rst_sources != prev_rst_sources && edge_detected) begin
            reset_history <= {reset_history[11:0], rst_sources};
        end
    end
endmodule