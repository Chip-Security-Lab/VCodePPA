module periodic_status_sync #(parameter STATUS_WIDTH = 16, PERIOD = 4) (
    input wire src_clk, dst_clk, reset,
    input wire [STATUS_WIDTH-1:0] status_src,
    output reg [STATUS_WIDTH-1:0] status_dst
);
    reg [STATUS_WIDTH-1:0] status_capture;
    reg toggle_src;
    reg [$clog2(PERIOD)-1:0] period_counter;
    reg [2:0] toggle_dst_sync;
    
    // Periodic capture in source domain
    always @(posedge src_clk) begin
        if (reset) begin
            period_counter <= 0;
            toggle_src <= 1'b0;
            status_capture <= {STATUS_WIDTH{1'b0}};
        end else begin
            if (period_counter == PERIOD-1) begin
                period_counter <= 0;
                status_capture <= status_src;
                toggle_src <= ~toggle_src;
            end else begin
                period_counter <= period_counter + 1'b1;
            end
        end
    end
    
    // Synchronize to destination domain
    always @(posedge dst_clk) begin
        if (reset) begin
            toggle_dst_sync <= 3'b0;
            status_dst <= {STATUS_WIDTH{1'b0}};
        end else begin
            toggle_dst_sync <= {toggle_dst_sync[1:0], toggle_src};
            if (toggle_dst_sync[2] != toggle_dst_sync[1])
                status_dst <= status_capture;
        end
    end
endmodule