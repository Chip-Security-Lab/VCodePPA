//SystemVerilog
// Top-level module: reset_source_control
module reset_source_control(
    input  wire        clk,
    input  wire        master_rst_n,
    input  wire [7:0]  reset_sources,   // Active high reset signals
    input  wire [7:0]  enable_mask,     // 1=enabled, 0=disabled
    output wire [7:0]  reset_status,
    output wire        system_reset
);

    // Internal signal for masked sources
    wire [7:0] masked_sources;

    // Masking logic submodule
    reset_masking_unit u_reset_masking_unit (
        .clk           (clk),
        .rst_n         (master_rst_n),
        .reset_sources (reset_sources),
        .enable_mask   (enable_mask),
        .masked_sources(masked_sources)
    );

    // Status register submodule
    reset_status_reg u_reset_status_reg (
        .clk            (clk),
        .rst_n          (master_rst_n),
        .masked_sources (masked_sources),
        .reset_status   (reset_status)
    );

    // System reset generation submodule
    system_reset_gen u_system_reset_gen (
        .clk            (clk),
        .rst_n          (master_rst_n),
        .masked_sources (masked_sources),
        .system_reset   (system_reset)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_masking_unit
// Function: Masks the incoming reset sources with the enable mask.
// -----------------------------------------------------------------------------
module reset_masking_unit(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  reset_sources,
    input  wire [7:0]  enable_mask,
    output reg  [7:0]  masked_sources
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            masked_sources <= 8'h00;
        else
            masked_sources <= reset_sources & enable_mask;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_status_reg
// Function: Latches the masked reset sources as the reset status register.
// -----------------------------------------------------------------------------
module reset_status_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  masked_sources,
    output reg  [7:0]  reset_status
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_status <= 8'h00;
        else
            reset_status <= masked_sources;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: system_reset_gen
// Function: Generates a system reset signal if any masked reset source is active.
// -----------------------------------------------------------------------------
module system_reset_gen(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  masked_sources,
    output reg         system_reset
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            system_reset <= 1'b0;
        else
            system_reset <= |masked_sources;
    end
endmodule