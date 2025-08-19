//SystemVerilog
module periodic_status_sync #(
    parameter STATUS_WIDTH = 16,
    parameter PERIOD = 4
) (
    input  wire                     src_clk,
    input  wire                     dst_clk,
    input  wire                     reset,
    input  wire [STATUS_WIDTH-1:0]  status_src,
    output reg  [STATUS_WIDTH-1:0]  status_dst
);

    reg [STATUS_WIDTH-1:0] status_capture;
    reg                    toggle_src;
    reg [$clog2(PERIOD)-1:0] period_counter;
    reg [2:0]               toggle_dst_sync;

    // Pipeline register for status_capture to break long path
    reg [STATUS_WIDTH-1:0] status_capture_pipe;

    // Pipeline register for toggle_src to break long path
    reg toggle_src_pipe;

    // Pipeline register for toggle_dst_sync to break long path
    reg [2:0] toggle_dst_sync_pipe;

    // Pipeline register for status_dst to align with toggle detection
    reg [STATUS_WIDTH-1:0] status_dst_pipe;

    // ----------------------------------------------------------
    // Periodic counter logic in source clock domain
    // ----------------------------------------------------------
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            period_counter <= {($clog2(PERIOD)){1'b0}};
        end else if (period_counter == PERIOD-1) begin
            period_counter <= {($clog2(PERIOD)){1'b0}};
        end else begin
            period_counter <= period_counter + 1'b1;
        end
    end

    // ----------------------------------------------------------
    // Status capture and toggle generation in source domain
    // ----------------------------------------------------------
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            status_capture      <= {STATUS_WIDTH{1'b0}};
            toggle_src          <= 1'b0;
            status_capture_pipe <= {STATUS_WIDTH{1'b0}};
            toggle_src_pipe     <= 1'b0;
        end else if (period_counter == PERIOD-1) begin
            status_capture      <= status_src;
            toggle_src          <= ~toggle_src;
            status_capture_pipe <= status_src;
            toggle_src_pipe     <= ~toggle_src;
        end else begin
            status_capture_pipe <= status_capture;
            toggle_src_pipe     <= toggle_src;
        end
    end

    // ----------------------------------------------------------
    // Synchronizer for toggle_src into destination domain
    // ----------------------------------------------------------
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            toggle_dst_sync      <= 3'b000;
            toggle_dst_sync_pipe <= 3'b000;
        end else begin
            toggle_dst_sync      <= {toggle_dst_sync[1:0], toggle_src_pipe};
            toggle_dst_sync_pipe <= toggle_dst_sync;
        end
    end

    // ----------------------------------------------------------
    // Status update in destination domain (pipelined)
    // ----------------------------------------------------------
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            status_dst_pipe <= {STATUS_WIDTH{1'b0}};
            status_dst      <= {STATUS_WIDTH{1'b0}};
        end else if (toggle_dst_sync_pipe[2] != toggle_dst_sync_pipe[1]) begin
            status_dst_pipe <= status_capture_pipe;
            status_dst      <= status_capture_pipe;
        end else begin
            status_dst      <= status_dst_pipe;
        end
    end

endmodule