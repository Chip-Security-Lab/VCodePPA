//SystemVerilog
//IEEE 1364-2005 Verilog
module handshake_sync #(parameter DW=32) (
    input  wire             src_clk,
    input  wire             dst_clk,
    input  wire             rst,
    input  wire [DW-1:0]    data_in,
    output reg  [DW-1:0]    data_out,
    output reg              ack
);

    // Source to destination synchronizer pipeline (req)
    reg req_sync_stage1, req_sync_stage2, req_sync_stage3;
    reg req_flag_src_stage1, req_flag_src_stage2;
    reg req_flag_dst_stage1, req_flag_dst_stage2;

    // Destination to source synchronizer pipeline (ack)
    reg ack_sync_stage1, ack_sync_stage2, ack_sync_stage3;
    reg ack_flag_dst_stage1, ack_flag_dst_stage2;
    reg ack_flag_src_stage1, ack_flag_src_stage2;

    // Data pipeline in src domain
    reg [DW-1:0] data_latch_stage1, data_latch_stage2;

    // Pipeline: src_clk domain logic
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            data_latch_stage1        <= {DW{1'b0}};
            data_latch_stage2        <= {DW{1'b0}};
            req_flag_src_stage1      <= 1'b0;
            req_flag_src_stage2      <= 1'b0;
        end else begin
            // Stage 1: Latch data and generate req_flag
            if (!req_flag_src_stage1 && !ack_flag_src_stage2) begin
                data_latch_stage1   <= data_in;
                req_flag_src_stage1 <= 1'b1;
            end else if (ack_flag_src_stage2) begin
                req_flag_src_stage1 <= 1'b0;
            end

            // Stage 2: Pipeline data and req_flag
            data_latch_stage2      <= data_latch_stage1;
            req_flag_src_stage2    <= req_flag_src_stage1;
        end
    end

    // Pipeline: Synchronize req_flag from src_clk to dst_clk (3-stage)
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            req_sync_stage1         <= 1'b0;
            req_sync_stage2         <= 1'b0;
            req_sync_stage3         <= 1'b0;
            req_flag_dst_stage1     <= 1'b0;
            req_flag_dst_stage2     <= 1'b0;
        end else begin
            req_sync_stage1         <= req_flag_src_stage2;
            req_sync_stage2         <= req_sync_stage1;
            req_sync_stage3         <= req_sync_stage2;
            // Stage 1: Sample the synchronized req
            req_flag_dst_stage1     <= req_sync_stage3;
            // Stage 2: Pipeline for downstream logic
            req_flag_dst_stage2     <= req_flag_dst_stage1;
        end
    end

    // Pipeline: dst_clk domain logic for ack_flag
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            ack_flag_dst_stage1     <= 1'b0;
            ack_flag_dst_stage2     <= 1'b0;
        end else begin
            // Stage 1: Generate ack_flag
            if (req_flag_dst_stage2 && !ack_flag_dst_stage1) begin
                ack_flag_dst_stage1 <= 1'b1;
            end else if (!req_flag_dst_stage2) begin
                ack_flag_dst_stage1 <= 1'b0;
            end
            // Stage 2: Pipeline ack_flag
            ack_flag_dst_stage2     <= ack_flag_dst_stage1;
        end
    end

    // Pipeline: Synchronize ack_flag from dst_clk to src_clk (3-stage)
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            ack_sync_stage1         <= 1'b0;
            ack_sync_stage2         <= 1'b0;
            ack_sync_stage3         <= 1'b0;
            ack_flag_src_stage1     <= 1'b0;
            ack_flag_src_stage2     <= 1'b0;
        end else begin
            ack_sync_stage1         <= ack_flag_dst_stage2;
            ack_sync_stage2         <= ack_sync_stage1;
            ack_sync_stage3         <= ack_sync_stage2;
            // Stage 1: Sample the synchronized ack
            ack_flag_src_stage1     <= ack_sync_stage3;
            // Stage 2: Pipeline for downstream logic
            ack_flag_src_stage2     <= ack_flag_src_stage1;
        end
    end

    // Pipeline: Output data_out in src_clk domain (aligned with req_flag_src_stage2)
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            data_out <= {DW{1'b0}};
        end else begin
            if (!req_flag_src_stage2 && !ack_flag_src_stage2) begin
                data_out <= data_latch_stage2;
            end
        end
    end

    // Pipeline: Output ack in dst_clk domain (aligned with ack_flag_dst_stage2)
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            ack <= 1'b0;
        end else begin
            ack <= ack_flag_dst_stage2;
        end
    end

endmodule