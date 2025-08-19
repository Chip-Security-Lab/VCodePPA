//SystemVerilog
module log_pipeline_valid_ready (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire        data_in_valid,
    output wire       data_in_ready,
    output wire [15:0] data_out,
    output wire        data_out_valid,
    input wire         data_out_ready
);
    // Pipeline registers for data
    reg [15:0] pipe_reg_stage0;
    reg [15:0] pipe_reg_stage1;
    reg [15:0] pipe_reg_stage2;
    reg [15:0] pipe_reg_stage3;

    // Buffered log2 calculation output
    reg [3:0] log2_buf_stage0;
    reg [3:0] log2_buf_stage1;

    // Buffered input signal
    reg [15:0] in_buf_stage0;
    reg [15:0] in_buf_stage1;

    // Buffered index variable for log2 calculation
    reg [4:0] i_buf_stage0;
    reg [4:0] i_buf_stage1;

    // Pipeline valid signals
    reg valid_stage0, valid_stage1, valid_stage2, valid_stage3;

    // Log2 calculation function
    function [3:0] log2_func;
        input [15:0] value;
        integer idx;
        begin
            log2_func = 0;
            for (idx = 15; idx >= 0; idx = idx - 1)
                if (value[idx]) log2_func = idx[3:0];
        end
    endfunction

    // Ready signal for stage 0 (input)
    assign data_in_ready = (!valid_stage0) || (valid_stage0 && stage0_ready_go);

    // Output assignments
    assign data_out      = pipe_reg_stage3;
    assign data_out_valid = valid_stage3;

    // Internal ready-go for each stage
    wire stage0_ready_go, stage1_ready_go, stage2_ready_go, stage3_ready_go;

    assign stage0_ready_go = (!valid_stage0) || (valid_stage1 && stage1_ready_go);
    assign stage1_ready_go = (!valid_stage1) || (valid_stage2 && stage2_ready_go);
    assign stage2_ready_go = (!valid_stage2) || (valid_stage3 && stage3_ready_go);
    assign stage3_ready_go = data_out_ready || (!valid_stage3);

    // Pipeline stages with valid-ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_buf_stage0    <= 16'b0;
            i_buf_stage0     <= 5'b0;
            in_buf_stage1    <= 16'b0;
            i_buf_stage1     <= 5'b0;
            log2_buf_stage0  <= 4'b0;
            log2_buf_stage1  <= 4'b0;
            pipe_reg_stage0  <= 16'b0;
            pipe_reg_stage1  <= 16'b0;
            pipe_reg_stage2  <= 16'b0;
            pipe_reg_stage3  <= 16'b0;
            valid_stage0     <= 1'b0;
            valid_stage1     <= 1'b0;
            valid_stage2     <= 1'b0;
            valid_stage3     <= 1'b0;
        end else begin
            // Stage 0
            if (stage0_ready_go) begin
                if (data_in_valid && data_in_ready) begin
                    in_buf_stage0  <= data_in;
                    i_buf_stage0   <= 5'd15;
                    valid_stage0   <= 1'b1;
                end else begin
                    valid_stage0   <= 1'b0;
                end
            end

            // Stage 1
            if (stage1_ready_go) begin
                if (valid_stage0) begin
                    in_buf_stage1   <= in_buf_stage0;
                    i_buf_stage1    <= i_buf_stage0;
                    log2_buf_stage0 <= log2_func(in_buf_stage0);
                    valid_stage1    <= 1'b1;
                end else begin
                    valid_stage1    <= 1'b0;
                end
            end

            // Stage 2
            if (stage2_ready_go) begin
                if (valid_stage1) begin
                    log2_buf_stage1 <= log2_buf_stage0;
                    pipe_reg_stage0 <= in_buf_stage1 + log2_buf_stage0;
                    valid_stage2    <= 1'b1;
                end else begin
                    valid_stage2    <= 1'b0;
                end
            end

            // Stage 3
            if (stage3_ready_go) begin
                if (valid_stage2) begin
                    pipe_reg_stage1 <= pipe_reg_stage0;
                    pipe_reg_stage2 <= pipe_reg_stage1;
                    pipe_reg_stage3 <= pipe_reg_stage2;
                    valid_stage3    <= 1'b1;
                end else begin
                    valid_stage3    <= 1'b0;
                end
            end

            // Data shifting for pipeline registers when not stalling
            if (!(valid_stage3 && !stage3_ready_go)) begin
                pipe_reg_stage1 <= pipe_reg_stage0;
                pipe_reg_stage2 <= pipe_reg_stage1;
                pipe_reg_stage3 <= pipe_reg_stage2;
            end
        end
    end

endmodule