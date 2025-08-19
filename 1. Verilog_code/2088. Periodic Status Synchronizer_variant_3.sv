//SystemVerilog
module periodic_status_sync #(parameter STATUS_WIDTH = 16, PERIOD = 4) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    input wire [STATUS_WIDTH-1:0] status_src,
    output reg [STATUS_WIDTH-1:0] status_dst
);
    reg [STATUS_WIDTH-1:0] status_capture;
    reg toggle_src;
    reg [$clog2(PERIOD)-1:0] period_counter;
    reg [2:0] toggle_dst_sync;
    reg [STATUS_WIDTH-1:0] status_capture_pipe; // Pipeline register for status_capture

    // Periodic capture in source domain
    always @(posedge src_clk) begin
        if (reset) begin
            period_counter <= {($clog2(PERIOD)){1'b0}};
            toggle_src <= 1'b0;
            status_capture <= {STATUS_WIDTH{1'b0}};
        end else begin
            if (period_counter == PERIOD-1) begin
                period_counter <= {($clog2(PERIOD)){1'b0}};
                status_capture <= status_src;
                toggle_src <= ~toggle_src;
            end else begin
                period_counter <= period_counter + 1'b1;
            end
        end
    end

    // Pipeline the status_capture to break the long combinational path
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            status_capture_pipe <= {STATUS_WIDTH{1'b0}};
        end else begin
            status_capture_pipe <= status_capture;
        end
    end

    // Synchronize to destination domain with pipeline for toggle and status
    reg toggle_src_pipe;
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            toggle_src_pipe <= 1'b0;
        end else begin
            toggle_src_pipe <= toggle_src;
        end
    end

    reg [2:0] toggle_dst_sync_pipe;
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            toggle_dst_sync <= 3'b0;
            toggle_dst_sync_pipe <= 3'b0;
        end else begin
            toggle_dst_sync <= {toggle_dst_sync[1:0], toggle_src_pipe};
            toggle_dst_sync_pipe <= toggle_dst_sync;
        end
    end

    reg [STATUS_WIDTH-1:0] status_capture_sync1;
    reg [STATUS_WIDTH-1:0] status_capture_sync2;

    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            status_capture_sync1 <= {STATUS_WIDTH{1'b0}};
            status_capture_sync2 <= {STATUS_WIDTH{1'b0}};
        end else begin
            status_capture_sync1 <= status_capture_pipe;
            status_capture_sync2 <= status_capture_sync1;
        end
    end

    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            status_dst <= {STATUS_WIDTH{1'b0}};
        end else begin
            if (toggle_dst_sync_pipe[2] != toggle_dst_sync_pipe[1])
                status_dst <= status_capture_sync2;
        end
    end

endmodule