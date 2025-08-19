//SystemVerilog
// Top-level CDC_Shifter module with hierarchical structure

module CDC_Shifter #(
    parameter WIDTH = 8
)(
    input  wire                 src_clk,
    input  wire                 dst_clk,
    input  wire [WIDTH-1:0]     data_in,
    output wire [WIDTH-1:0]     data_out
);

    // Internal signals for inter-module connections
    wire [WIDTH-1:0] captured_data;
    wire             captured_valid;

    wire [WIDTH-1:0] synced_data;
    wire             synced_valid;

    // Stage 1: Data Capture in Source Clock Domain
    CDC_DataCapture #(
        .WIDTH(WIDTH)
    ) u_data_capture (
        .clk         (src_clk),
        .data_in     (data_in),
        .data_out    (captured_data),
        .valid_out   (captured_valid)
    );

    // Stage 2: Synchronization from Source to Destination Clock Domain
    CDC_Synchronizer #(
        .WIDTH(WIDTH)
    ) u_synchronizer (
        .src_data    (captured_data),
        .src_valid   (captured_valid),
        .dst_clk     (dst_clk),
        .dst_data    (synced_data),
        .dst_valid   (synced_valid)
    );

    // Stage 3: Output Register with Valid Gating in Destination Clock Domain
    CDC_OutputRegister #(
        .WIDTH(WIDTH)
    ) u_output_register (
        .clk         (dst_clk),
        .data_in     (synced_data),
        .valid_in    (synced_valid),
        .data_out    (data_out)
    );

endmodule

//-----------------------------------------------------------------------------
// CDC_DataCapture
// Captures input data and generates a valid signal in the source clock domain
//-----------------------------------------------------------------------------
module CDC_DataCapture #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire [WIDTH-1:0]     data_in,
    output reg  [WIDTH-1:0]     data_out,
    output reg                  valid_out
);
    always @(posedge clk) begin
        data_out  <= data_in;
        valid_out <= 1'b1;
    end
endmodule

//-----------------------------------------------------------------------------
// CDC_Synchronizer
// 2-stage synchronizer for data and valid signals from src to dst clock domain
//-----------------------------------------------------------------------------
module CDC_Synchronizer #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0]     src_data,
    input  wire                 src_valid,
    input  wire                 dst_clk,
    output reg  [WIDTH-1:0]     dst_data,
    output reg                  dst_valid
);
    // Synchronizer registers for valid
    reg valid_sync1, valid_sync2;
    // Synchronizer registers for data
    reg [WIDTH-1:0] data_sync1, data_sync2;

    // Synchronize valid signal
    always @(posedge dst_clk) begin
        valid_sync1 <= src_valid;
        valid_sync2 <= valid_sync1;
    end

    // Synchronize data signal
    always @(posedge dst_clk) begin
        data_sync1 <= src_data;
        data_sync2 <= data_sync1;
    end

    // Assign outputs
    always @(posedge dst_clk) begin
        dst_data  <= data_sync2;
        dst_valid <= valid_sync2;
    end
endmodule

//-----------------------------------------------------------------------------
// CDC_OutputRegister
// Output register with valid gating in the destination clock domain
//-----------------------------------------------------------------------------
module CDC_OutputRegister #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire [WIDTH-1:0]     data_in,
    input  wire                 valid_in,
    output reg  [WIDTH-1:0]     data_out
);
    reg valid_latched;
    always @(posedge clk) begin
        if (valid_in) begin
            data_out      <= data_in;
            valid_latched <= 1'b1;
        end else begin
            valid_latched <= 1'b0;
        end
    end
endmodule