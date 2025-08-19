//SystemVerilog
// Top-level module: slow_to_fast_sync
// Function: Synchronizes data transfer from a slow clock domain to a fast clock domain using toggle and synchronizer logic.
module slow_to_fast_sync #(
    parameter WIDTH = 12
) (
    input  wire                  slow_clk,
    input  wire                  fast_clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      slow_data,
    output wire [WIDTH-1:0]      fast_data,
    output wire                  data_valid
);

    // Internal signals for inter-module connections
    wire                         slow_toggle_out;
    wire [WIDTH-1:0]             captured_data;
    wire [2:0]                   fast_sync_out;
    wire                         fast_toggle_prev_out;

    // Slow domain logic: capture data and generate toggle
    slow_domain_capture #(
        .WIDTH(WIDTH)
    ) u_slow_domain_capture (
        .clk           (slow_clk),
        .rst_n         (rst_n),
        .data_in       (slow_data),
        .toggle_out    (slow_toggle_out),
        .data_captured (captured_data)
    );

    // Fast domain synchronizer: synchronize toggle signal to fast clock domain
    fast_domain_synchronizer u_fast_domain_synchronizer (
        .clk           (fast_clk),
        .rst_n         (rst_n),
        .toggle_in     (slow_toggle_out),
        .sync_out      (fast_sync_out),
        .toggle_prev   (fast_toggle_prev_out)
    );

    // Fast domain data latch and valid flag logic
    fast_domain_latch #(
        .WIDTH(WIDTH)
    ) u_fast_domain_latch (
        .clk           (fast_clk),
        .rst_n         (rst_n),
        .sync_toggle   (fast_sync_out),
        .toggle_prev   (fast_toggle_prev_out),
        .data_in       (captured_data),
        .data_out      (fast_data),
        .data_valid    (data_valid)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: slow_domain_capture
// Function: Captures data and generates a toggle in the slow clock domain
// -----------------------------------------------------------------------------
module slow_domain_capture #(
    parameter WIDTH = 12
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      data_in,
    output reg                   toggle_out,
    output reg [WIDTH-1:0]       data_captured
);

    // Toggle register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_out <= 1'b0;
        end else begin
            toggle_out <= ~toggle_out;
        end
    end

    // Data capture register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_captured <= {WIDTH{1'b0}};
        end else begin
            data_captured <= data_in;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: fast_domain_synchronizer
// Function: Synchronizes the toggle signal into the fast clock domain using a 3-stage shift register
// -----------------------------------------------------------------------------
module fast_domain_synchronizer (
    input  wire clk,
    input  wire rst_n,
    input  wire toggle_in,
    output reg  [2:0] sync_out,
    output reg        toggle_prev
);

    // 3-stage synchronizer shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_out <= 3'b0;
        end else begin
            sync_out <= {sync_out[1:0], toggle_in};
        end
    end

    // Previous toggle register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_prev <= 1'b0;
        end else begin
            toggle_prev <= sync_out[2];
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: fast_domain_latch
// Function: Detects toggle edge and latches data in fast clock domain, asserts data_valid for one cycle
// -----------------------------------------------------------------------------
module fast_domain_latch #(
    parameter WIDTH = 12
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [2:0]            sync_toggle,
    input  wire                  toggle_prev,
    input  wire [WIDTH-1:0]      data_in,
    output reg  [WIDTH-1:0]      data_out,
    output reg                   data_valid
);

    reg toggle_edge_detected;

    // Edge detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_edge_detected <= 1'b0;
        end else begin
            toggle_edge_detected <= (sync_toggle[2] != toggle_prev);
        end
    end

    // Data valid flag logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= toggle_edge_detected;
        end
    end

    // Data output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else if (toggle_edge_detected) begin
            data_out <= data_in;
        end
    end

endmodule