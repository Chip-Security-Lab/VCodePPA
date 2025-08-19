//SystemVerilog
// Top-level module: Hierarchical reset source control
module reset_source_control(
    input  wire        clk,
    input  wire        master_rst_n,
    input  wire [7:0]  reset_sources,   // Active high reset signals
    input  wire [7:0]  enable_mask,     // 1=enabled, 0=disabled
    output wire [7:0]  reset_status,
    output wire        system_reset
);

    wire [7:0] masked_sources;
    wire [7:0] status_reg_out;
    wire       system_reset_reg_out;

    // Mask Generation Submodule
    reset_mask_gen u_reset_mask_gen (
        .reset_sources (reset_sources),
        .enable_mask   (enable_mask),
        .masked_sources(masked_sources)
    );

    // Reset Status Register Submodule
    reset_status_reg u_reset_status_reg (
        .clk          (clk),
        .rst_n        (master_rst_n),
        .masked_in    (masked_sources),
        .status_out   (status_reg_out)
    );

    // System Reset Generation Submodule
    system_reset_gen u_system_reset_gen (
        .clk              (clk),
        .rst_n            (master_rst_n),
        .masked_sources   (masked_sources),
        .system_reset_out (system_reset_reg_out)
    );

    assign reset_status  = status_reg_out;
    assign system_reset  = system_reset_reg_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_mask_gen
// Description: Generates masked reset sources based on enable mask
// -----------------------------------------------------------------------------
module reset_mask_gen(
    input  wire [7:0] reset_sources,
    input  wire [7:0] enable_mask,
    output wire [7:0] masked_sources
);
    assign masked_sources = reset_sources & enable_mask;
endmodule

// -----------------------------------------------------------------------------
// Submodule: reset_status_reg
// Description: Register for storing current masked reset status
// -----------------------------------------------------------------------------
module reset_status_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  masked_in,
    output reg  [7:0]  status_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            status_out <= 8'h00;
        else
            status_out <= masked_in;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: system_reset_gen
// Description: Generates system reset signal if any masked source is active
// -----------------------------------------------------------------------------
module system_reset_gen(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  masked_sources,
    output reg         system_reset_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            system_reset_out <= 1'b0;
        else
            system_reset_out <= |masked_sources;
    end
endmodule