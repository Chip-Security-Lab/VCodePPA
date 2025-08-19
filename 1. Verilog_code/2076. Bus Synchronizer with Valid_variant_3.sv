//SystemVerilog
module bus_sync_valid #(parameter BUS_WIDTH = 16) (
    input  wire                   src_clk,
    input  wire                   dst_clk,
    input  wire                   rst,
    input  wire [BUS_WIDTH-1:0]   data_in,
    input  wire                   valid_in,
    output reg                    valid_out,
    output reg  [BUS_WIDTH-1:0]   data_out
);

    ////////////////////////////////////////////////////////////////////////////////
    // Source Domain Registers
    ////////////////////////////////////////////////////////////////////////////////
    reg                           valid_toggle;

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain Registers
    ////////////////////////////////////////////////////////////////////////////////
    reg   [2:0]                   sync_valid;
    reg   [BUS_WIDTH-1:0]         data_capture_sync;
    reg   [BUS_WIDTH-1:0]         data_capture_sync_d1;
    reg                           valid_pulse_d;

    ////////////////////////////////////////////////////////////////////////////////
    // Wire Declarations
    ////////////////////////////////////////////////////////////////////////////////
    wire                          valid_pulse;

    ////////////////////////////////////////////////////////////////////////////////
    // Source Domain: Toggle valid signal on valid_in assertion
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Generates a toggle signal to indicate a new valid event in the source clock domain
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            valid_toggle <= 1'b0;
        end else if (valid_in) begin
            valid_toggle <= ~valid_toggle;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Synchronize valid_toggle to destination clock
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Three-stage synchronizer for metastability protection
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            sync_valid <= 3'b000;
        end else begin
            sync_valid <= {sync_valid[1:0], valid_toggle};
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Generate valid_pulse when toggle detected
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Detects edge of toggle for a single valid_pulse
    assign valid_pulse = sync_valid[2] ^ sync_valid[1];

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Pipeline data_in to align with valid_pulse
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Capture data_in on destination clock domain for synchronization
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_capture_sync <= {BUS_WIDTH{1'b0}};
        end else begin
            data_capture_sync <= data_in;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Pipeline data_capture_sync for alignment
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Pipeline register for data alignment
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_capture_sync_d1 <= {BUS_WIDTH{1'b0}};
        end else begin
            data_capture_sync_d1 <= data_capture_sync;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Pipeline valid_pulse for output alignment
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Pipeline register for valid_pulse to align with data
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            valid_pulse_d <= 1'b0;
        end else begin
            valid_pulse_d <= valid_pulse;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Generate valid_out signal
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Output valid pulse to indicate new data has arrived
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_pulse_d;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Destination Domain: Latch data_out on valid_out assertion
    ////////////////////////////////////////////////////////////////////////////////
    // Function: Latch synchronized data into output register when valid_out is asserted
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_out <= {BUS_WIDTH{1'b0}};
        end else if (valid_pulse_d) begin
            data_out <= data_capture_sync_d1;
        end
    end

endmodule