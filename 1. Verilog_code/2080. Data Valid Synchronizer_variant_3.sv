//SystemVerilog
module data_valid_sync #(parameter WIDTH = 32) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset_n,
    input wire [WIDTH-1:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg [WIDTH-1:0] data_out,
    output reg valid_out,
    input wire ready_in
);

    // Stage 1 (Source Domain): Capture input and initiate request
    reg [WIDTH-1:0] data_stage1;
    reg req_stage1, ack_stage1;
    reg valid_stage1;

    // Stage 2 (Source Domain to Meta): Synchronize request across clock domains
    reg req_stage2_meta, req_stage2_dst;
    reg ack_stage2_meta, ack_stage2_src;
    reg valid_stage2;

    // Stage 3 (Destination Domain): Data transfer and handshake
    reg [WIDTH-1:0] data_stage3;
    reg ack_stage3_dst, ack_stage3_meta;
    reg req_stage3_dst, req_stage3_meta;
    reg valid_stage3;
    reg valid_stage4;
    reg [WIDTH-1:0] data_stage4;

    // Pipeline flush logic
    reg flush_stage1, flush_stage2, flush_stage3, flush_stage4;

    // Forwarding logic (for data dependency safety)
    wire req_src_pulse, ack_dst_pulse;

    // Stage 1: Source domain input capture and request generation
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_stage1    <= 1'b0;
            ack_stage1    <= 1'b0;
            valid_stage1  <= 1'b0;
            data_stage1   <= {WIDTH{1'b0}};
            flush_stage1  <= 1'b0;
        end else begin
            ack_stage1   <= ack_stage2_src;
            // Pipeline flush logic for stage 1
            if (flush_stage1) begin
                req_stage1    <= 1'b0;
                valid_stage1  <= 1'b0;
                flush_stage1  <= 1'b0;
            end else if (valid_in && (ack_stage1 == req_stage1) && !req_stage1) begin
                data_stage1   <= data_in;
                req_stage1    <= 1'b1;
                valid_stage1  <= 1'b1;
            end else if (~valid_in && (ack_stage1 == req_stage1) && req_stage1) begin
                req_stage1    <= 1'b0;
                valid_stage1  <= 1'b0;
            end
        end
    end

    // Stage 2: Source -> Meta synchronizer for request
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_stage2_meta  <= 1'b0;
            valid_stage2     <= 1'b0;
            flush_stage2     <= 1'b0;
        end else begin
            req_stage2_meta  <= req_stage1;
            // Pipeline flush logic for stage 2
            if (flush_stage2) begin
                valid_stage2 <= 1'b0;
                flush_stage2 <= 1'b0;
            end else begin
                valid_stage2 <= valid_stage1;
            end
        end
    end

    // Cross to destination clock domain for request synchronizer (double flip-flop)
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_stage2_dst  <= 1'b0;
            req_stage3_meta <= 1'b0;
        end else begin
            req_stage2_dst  <= req_stage2_meta;
            req_stage3_meta <= req_stage2_dst;
        end
    end

    // Stage 3: Destination domain handshake and data transfer
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_stage3_dst   <= 1'b0;
            ack_stage3_dst   <= 1'b0;
            valid_stage3     <= 1'b0;
            data_stage3      <= {WIDTH{1'b0}};
            flush_stage3     <= 1'b0;
        end else begin
            req_stage3_dst <= req_stage3_meta;

            // Pipeline flush logic for stage 3
            if (flush_stage3) begin
                valid_stage3 <= 1'b0;
                flush_stage3 <= 1'b0;
            end else if ((req_stage3_dst ^ ack_stage3_dst) && ready_in) begin
                valid_stage3 <= 1'b1;
                data_stage3  <= data_stage1;
                ack_stage3_dst <= req_stage3_dst;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // Stage 4: Output register stage (final output, with valid and flush)
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            data_stage4    <= {WIDTH{1'b0}};
            valid_stage4   <= 1'b0;
            data_out       <= {WIDTH{1'b0}};
            valid_out      <= 1'b0;
            flush_stage4   <= 1'b0;
        end else begin
            if (flush_stage4) begin
                valid_stage4 <= 1'b0;
                valid_out    <= 1'b0;
                flush_stage4 <= 1'b0;
            end else begin
                data_stage4  <= data_stage3;
                valid_stage4 <= valid_stage3;
                data_out     <= data_stage4;
                valid_out    <= valid_stage4;
            end
        end
    end

    // Backward handshake: ack synchronizer from dst to src clock domain (double flip-flop)
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            ack_stage3_meta <= 1'b0;
        end else begin
            ack_stage3_meta <= ack_stage3_dst;
        end
    end

    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            ack_stage2_meta <= 1'b0;
            ack_stage2_src  <= 1'b0;
        end else begin
            ack_stage2_meta <= ack_stage3_meta;
            ack_stage2_src  <= ack_stage2_meta;
        end
    end

    // Pipeline flush logic controller (optional, can be connected to external flush)
    always @(*) begin
        flush_stage1 = 1'b0;
        flush_stage2 = 1'b0;
        flush_stage3 = 1'b0;
        flush_stage4 = 1'b0;
        // Example: add flush logic if needed, e.g., on reset or external signal
    end

    // Ready output: indicate when source can accept new data
    assign ready_out = ~(req_stage1 ^ ack_stage1);

endmodule