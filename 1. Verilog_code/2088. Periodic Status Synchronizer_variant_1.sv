//SystemVerilog
module periodic_status_sync #(parameter STATUS_WIDTH = 16, PERIOD = 4) (
    input wire src_clk, 
    input wire dst_clk, 
    input wire reset,
    input wire [STATUS_WIDTH-1:0] status_src,
    output wire [STATUS_WIDTH-1:0] status_dst
);
    reg [STATUS_WIDTH-1:0] status_capture_reg;
    reg toggle_src_reg;
    reg [$clog2(PERIOD)-1:0] period_counter_reg;
    reg [2:0] toggle_dst_sync_reg;
    reg toggle_dst_sampled1_reg, toggle_dst_sampled2_reg;
    reg [STATUS_WIDTH-1:0] status_src_sampled1_reg, status_src_sampled2_reg;

    // Move the output register (status_dst) to before the domain crossing
    // Capture and register status_src in src_clk domain
    always @(posedge src_clk) begin
        if (reset) begin
            period_counter_reg <= {($clog2(PERIOD)){1'b0}};
            toggle_src_reg <= 1'b0;
            status_capture_reg <= {STATUS_WIDTH{1'b0}};
        end else begin
            if (&period_counter_reg) begin
                period_counter_reg <= {($clog2(PERIOD)){1'b0}};
                status_capture_reg <= status_src;
                toggle_src_reg <= ~toggle_src_reg;
            end else begin
                period_counter_reg <= period_counter_reg + 1'b1;
            end
        end
    end

    // Synchronize toggle signal into destination domain
    always @(posedge dst_clk) begin
        if (reset) begin
            toggle_dst_sync_reg <= 3'b000;
        end else begin
            toggle_dst_sync_reg <= {toggle_dst_sync_reg[1:0], toggle_src_reg};
        end
    end

    // Move the output register before the output; sample status_capture_reg in dst domain
    always @(posedge dst_clk) begin
        if (reset) begin
            toggle_dst_sampled1_reg <= 1'b0;
            toggle_dst_sampled2_reg <= 1'b0;
            status_src_sampled1_reg <= {STATUS_WIDTH{1'b0}};
            status_src_sampled2_reg <= {STATUS_WIDTH{1'b0}};
        end else begin
            toggle_dst_sampled1_reg <= toggle_dst_sync_reg[2];
            toggle_dst_sampled2_reg <= toggle_dst_sampled1_reg;
            status_src_sampled1_reg <= status_capture_reg;
            status_src_sampled2_reg <= status_src_sampled1_reg;
        end
    end

    // Output combinational logic; output changes only when toggle edge detected
    assign status_dst = (toggle_dst_sampled1_reg & ~toggle_dst_sampled2_reg) ? status_src_sampled2_reg : status_dst;

endmodule