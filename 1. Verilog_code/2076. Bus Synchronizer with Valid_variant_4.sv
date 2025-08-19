//SystemVerilog
// Top-level module: Hierarchical bus synchronizer with valid signal
module bus_sync_valid #(parameter BUS_WIDTH = 16) (
    input  wire                src_clk,
    input  wire                dst_clk,
    input  wire                rst,
    input  wire [BUS_WIDTH-1:0] data_in,
    input  wire                valid_in,
    output wire                valid_out,
    output wire [BUS_WIDTH-1:0] data_out
);

    // Internal signals for inter-module connectivity
    wire                       valid_toggle_src;
    wire [2:0]                 sync_valid_dst;
    wire                       valid_edge_dst;
    wire [BUS_WIDTH-1:0]       data_capture_dst_wire;

    // Source domain: Valid toggle generator
    bus_sync_valid_toggle u_valid_toggle (
        .src_clk     (src_clk),
        .rst         (rst),
        .valid_in    (valid_in),
        .valid_toggle(valid_toggle_src)
    );

    // Destination domain: Valid toggle synchronizer and edge detector
    bus_sync_valid_synchronizer u_valid_sync (
        .dst_clk      (dst_clk),
        .rst          (rst),
        .valid_toggle (valid_toggle_src),
        .sync_valid   (sync_valid_dst),
        .valid_edge   (valid_edge_dst)
    );

    // Destination domain: Data capture and output logic
    bus_sync_valid_data #( .BUS_WIDTH(BUS_WIDTH) ) u_data_capture (
        .dst_clk           (dst_clk),
        .rst               (rst),
        .valid_edge        (valid_edge_dst),
        .data_in           (data_in),
        .data_capture_prev (data_capture_dst_wire),
        .data_capture_next (data_capture_dst_wire),
        .valid_out         (valid_out),
        .data_out          (data_out)
    );

endmodule

// -------------------------------------------------------------
// Submodule: bus_sync_valid_toggle
// Function: Generates a toggle signal in the source clock domain on valid_in
// -------------------------------------------------------------
module bus_sync_valid_toggle (
    input  wire src_clk,
    input  wire rst,
    input  wire valid_in,
    output reg  valid_toggle
);
    always @(posedge src_clk) begin
        if (rst) begin
            valid_toggle <= 1'b0;
        end else if (valid_in) begin
            valid_toggle <= ~valid_toggle;
        end
    end
endmodule

// -------------------------------------------------------------
// Submodule: bus_sync_valid_synchronizer
// Function: Synchronizes valid_toggle into the destination clock domain and detects toggle edge
// -------------------------------------------------------------
module bus_sync_valid_synchronizer (
    input  wire dst_clk,
    input  wire rst,
    input  wire valid_toggle,
    output reg [2:0] sync_valid,
    output reg       valid_edge
);
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_valid <= 3'b0;
            valid_edge <= 1'b0;
        end else begin
            sync_valid <= {sync_valid[1:0], valid_toggle};
            valid_edge <= sync_valid[2] ^ sync_valid[1];
        end
    end
endmodule

// -------------------------------------------------------------
// Submodule: bus_sync_valid_data
// Function: Captures data_in on valid_edge and outputs synchronized data and valid
// -------------------------------------------------------------
module bus_sync_valid_data #(parameter BUS_WIDTH = 16) (
    input  wire                dst_clk,
    input  wire                rst,
    input  wire                valid_edge,
    input  wire [BUS_WIDTH-1:0] data_in,
    input  wire [BUS_WIDTH-1:0] data_capture_prev,
    output reg  [BUS_WIDTH-1:0] data_capture_next,
    output reg                 valid_out,
    output reg  [BUS_WIDTH-1:0] data_out
);
    // 3-bit parallel borrow lookahead subtractor wires
    wire [2:0] minuend;
    wire [2:0] subtrahend;
    wire [2:0] difference;
    wire       borrow_out;

    assign minuend    = data_in[2:0];
    assign subtrahend = data_capture_prev[2:0];

    borrow_lookahead_subtractor_3bit u_subtractor (
        .a        (minuend),
        .b        (subtrahend),
        .diff     (difference),
        .borrow_o (borrow_out)
    );

    always @(posedge dst_clk) begin
        if (rst) begin
            data_capture_next <= {BUS_WIDTH{1'b0}};
            valid_out         <= 1'b0;
            data_out          <= {BUS_WIDTH{1'b0}};
        end else begin
            if (valid_edge) begin
                data_capture_next <= data_in;
            end
            valid_out <= valid_edge;
            if (valid_edge) begin
                data_out <= { { (BUS_WIDTH-3){1'b0} }, difference };
            end
        end
    end
endmodule

// -------------------------------------------------------------
// Submodule: 3-bit Parallel Borrow Lookahead Subtractor
// Function: Performs 3-bit subtraction using borrow lookahead logic
// -------------------------------------------------------------
module borrow_lookahead_subtractor_3bit (
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire [2:0] diff,
    output wire       borrow_o
);
    wire [2:0] generate_borrow;
    wire [2:0] propagate_borrow;
    wire [2:0] borrow;

    // Generate and propagate signals
    assign generate_borrow[0] = (~a[0]) & b[0];
    assign propagate_borrow[0] = ~(a[0] ^ b[0]);

    assign generate_borrow[1] = (~a[1]) & b[1];
    assign propagate_borrow[1] = ~(a[1] ^ b[1]);

    assign generate_borrow[2] = (~a[2]) & b[2];
    assign propagate_borrow[2] = ~(a[2] ^ b[2]);

    // Borrow chain
    assign borrow[0] = generate_borrow[0];
    assign borrow[1] = generate_borrow[1] | (propagate_borrow[1] & borrow[0]);
    assign borrow[2] = generate_borrow[2] | (propagate_borrow[2] & borrow[1]);

    // Difference calculation
    assign diff[0] = a[0] ^ b[0] ^ 1'b0;
    assign diff[1] = a[1] ^ b[1] ^ borrow[0];
    assign diff[2] = a[2] ^ b[2] ^ borrow[1];

    assign borrow_o = borrow[2];
endmodule