//SystemVerilog
module data_valid_sync_pipelined #(parameter WIDTH = 32) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset_n,
    input wire [WIDTH-1:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output wire [WIDTH-1:0] data_out,
    output wire valid_out,
    input wire ready_in
);

    // Stage 1: Source domain - capture input data and handshake request
    reg req_src_stage1, req_src_stage2;
    reg ack_src_stage1, ack_src_stage2;
    reg ack_meta_stage1, ack_meta_stage2;
    reg [WIDTH-1:0] data_reg_stage1, data_reg_stage2;
    reg valid_pipe_src_stage1, valid_pipe_src_stage2;

    // Stage 2: CDC meta FFs for req and ack
    reg req_meta_stage1, req_meta_stage2, req_dst_stage1, req_dst_stage2;
    reg ack_dst_stage1, ack_dst_stage2;
    reg ack_meta_dst_stage1, ack_meta_dst_stage2;

    // Stage 3: Destination domain - output and handshake acknowledge
    reg [WIDTH-1:0] data_reg_dst_stage1;
    reg valid_pipe_dst_stage1;
    reg ack_pipe_dst_stage1, ack_pipe_dst_stage2;

    // Output pipeline registers moved backward (retiming)
    reg [WIDTH-1:0] data_out_reg;
    reg valid_out_reg;

    // Flush logic
    wire flush_src, flush_dst;
    assign flush_src = !reset_n;
    assign flush_dst = !reset_n;

    // ------------------- Source Domain Pipeline -------------------
    // Stage 1: Capture data and issue request
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_src_stage1 <= 1'b0;
            ack_src_stage1 <= 1'b0;
            ack_meta_stage1 <= 1'b0;
            data_reg_stage1 <= {WIDTH{1'b0}};
            valid_pipe_src_stage1 <= 1'b0;
        end else begin
            ack_meta_stage1 <= ack_src_stage2;
            ack_src_stage1 <= ack_meta_stage1;
            if (valid_in && (req_src_stage1 == ack_src_stage1)) begin
                data_reg_stage1 <= data_in;
                req_src_stage1 <= ~req_src_stage1;
                valid_pipe_src_stage1 <= 1'b1;
            end else begin
                valid_pipe_src_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Pipeline register for source domain
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_src_stage2 <= 1'b0;
            data_reg_stage2 <= {WIDTH{1'b0}};
            valid_pipe_src_stage2 <= 1'b0;
        end else begin
            req_src_stage2 <= req_src_stage1;
            data_reg_stage2 <= data_reg_stage1;
            valid_pipe_src_stage2 <= valid_pipe_src_stage1;
        end
    end

    // ------------- CDC Pipeline: Request and ACK Crossing -------------

    // CDC for request signal
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_meta_stage1 <= 1'b0;
            req_meta_stage2 <= 1'b0;
            req_dst_stage1 <= 1'b0;
            req_dst_stage2 <= 1'b0;
        end else begin
            req_meta_stage1 <= req_src_stage2;
            req_meta_stage2 <= req_meta_stage1;
            req_dst_stage1 <= req_meta_stage2;
            req_dst_stage2 <= req_dst_stage1;
        end
    end

    // CDC for acknowledge signal
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            ack_meta_stage1 <= 1'b0;
            ack_meta_stage2 <= 1'b0;
            ack_src_stage2 <= 1'b0;
        end else begin
            ack_meta_stage1 <= ack_dst_stage2;
            ack_meta_stage2 <= ack_meta_stage1;
            ack_src_stage2 <= ack_meta_stage2;
        end
    end

    // ------------- Destination Domain Pipeline (retimed output registers) -------------
    // Stage 1: Capture data if request toggled and ready_in is high
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            data_reg_dst_stage1 <= {WIDTH{1'b0}};
            valid_pipe_dst_stage1 <= 1'b0;
            ack_dst_stage1 <= 1'b0;
        end else begin
            if ((req_dst_stage2 != ack_dst_stage1) && ready_in) begin
                data_reg_dst_stage1 <= data_reg_stage2;
                valid_pipe_dst_stage1 <= 1'b1;
                ack_dst_stage1 <= req_dst_stage2;
            end else begin
                valid_pipe_dst_stage1 <= 1'b0;
            end
        end
    end

    // Output pipeline registers moved backward (retiming)
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out_reg <= {WIDTH{1'b0}};
            valid_out_reg <= 1'b0;
        end else begin
            data_out_reg <= data_reg_dst_stage1;
            valid_out_reg <= valid_pipe_dst_stage1;
        end
    end

    // Output assignments
    assign data_out = data_out_reg;
    assign valid_out = valid_out_reg;

    // Ready output: indicate when the source can send new data
    assign ready_out = (req_src_stage1 == ack_src_stage1);

endmodule