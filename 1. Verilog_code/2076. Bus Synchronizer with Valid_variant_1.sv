//SystemVerilog
// Top-level module: Hierarchical Bus Synchronizer with Valid Signal (Refactored)
module bus_sync_valid #(parameter BUS_WIDTH = 16) (
    input  wire                  src_clk,
    input  wire                  dst_clk,
    input  wire                  rst,
    input  wire [BUS_WIDTH-1:0]  data_in,
    input  wire                  valid_in,
    output wire                  valid_out,
    output wire [BUS_WIDTH-1:0]  data_out
);

    // Internal signals for inter-module connections
    wire                         valid_toggle;
    wire [BUS_WIDTH-1:0]         data_capture;
    wire                         sync_valid_out;
    wire [BUS_WIDTH-1:0]         bus_data_out;

    // Source domain logic: Capture data and generate toggle for valid
    bus_sync_src #(.BUS_WIDTH(BUS_WIDTH)) u_src (
        .clk           (src_clk),
        .rst           (rst),
        .bus_in        (data_in),
        .valid_in      (valid_in),
        .valid_toggle  (valid_toggle),
        .bus_capture   (data_capture)
    );

    // Synchronizer: Synchronize the valid_toggle signal to destination clock domain
    toggle_synchronizer u_toggle_sync (
        .clk           (dst_clk),
        .rst           (rst),
        .toggle_in     (valid_toggle),
        .toggle_sync   (sync_valid_out)
    );

    // Destination domain logic: Generate valid_out and capture data
    bus_sync_dst #(.BUS_WIDTH(BUS_WIDTH)) u_dst (
        .clk           (dst_clk),
        .rst           (rst),
        .toggle_sync   (sync_valid_out),
        .bus_capture   (data_capture),
        .valid_out     (valid_out),
        .bus_out       (bus_data_out)
    );

    // Output assignments
    assign data_out = bus_data_out;

endmodule

//-----------------------------------------------------------------------------
// Source Domain Logic: Data Capture and Toggle Generation
//-----------------------------------------------------------------------------
module bus_sync_src #(parameter BUS_WIDTH = 16) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire [BUS_WIDTH-1:0]  bus_in,
    input  wire                  valid_in,
    output reg                   valid_toggle,
    output reg [BUS_WIDTH-1:0]   bus_capture
);
    // Captures bus_in data and toggles valid_toggle on valid_in pulse
    always @(posedge clk) begin
        if (rst) begin
            valid_toggle <= 1'b0;
            bus_capture  <= {BUS_WIDTH{1'b0}};
        end else if (valid_in) begin
            valid_toggle <= ~valid_toggle;
            bus_capture  <= bus_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Toggle Synchronizer: Synchronizes toggle signal across clock domains
//-----------------------------------------------------------------------------
module toggle_synchronizer (
    input  wire clk,
    input  wire rst,
    input  wire toggle_in,
    output reg  toggle_sync
);
    // 3-stage synchronizer for metastability protection
    reg [2:0] sync_stage;

    always @(posedge clk) begin
        if (rst) begin
            sync_stage  <= 3'b000;
            toggle_sync <= 1'b0;
        end else begin
            sync_stage  <= {sync_stage[1:0], toggle_in};
            toggle_sync <= sync_stage[2] ^ sync_stage[1];
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Destination Domain Logic: Output Generation on Synchronized Toggle
//-----------------------------------------------------------------------------
module bus_sync_dst #(parameter BUS_WIDTH = 16) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  toggle_sync,
    input  wire [BUS_WIDTH-1:0]  bus_capture,
    output reg                   valid_out,
    output reg [BUS_WIDTH-1:0]   bus_out
);
    // Latches data on toggle_sync pulse, asserts valid_out
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            bus_out   <= {BUS_WIDTH{1'b0}};
        end else begin
            valid_out <= toggle_sync;
            if (toggle_sync)
                bus_out <= bus_capture;
        end
    end
endmodule