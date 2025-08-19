//SystemVerilog
module q_format_converter_15_to_31_valid_ready #(
    parameter DATA_IN_WIDTH = 16,
    parameter DATA_OUT_WIDTH = 32
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [DATA_IN_WIDTH-1:0]     q15_in_data,
    input  wire                         q15_in_valid,
    output wire                         q15_in_ready,
    output wire [DATA_OUT_WIDTH-1:0]    q31_out_data,
    output wire                         q31_out_valid,
    input  wire                         q31_out_ready
);

    // First-stage buffered registers for high fanout signals
    reg  [DATA_IN_WIDTH-1:0]     q15_in_data_reg_stage1;
    reg                          q15_in_data_valid_reg_stage1;
    reg  [DATA_OUT_WIDTH-1:0]    q31_out_data_reg_stage1;
    reg                          q31_out_valid_reg_stage1;
    reg                          q31_out_ready_buf1;
    reg                          q31_out_ready_buf2;

    // Second-stage buffered registers for high fanout signals
    reg  [DATA_IN_WIDTH-1:0]     q15_in_data_reg_stage2;
    reg                          q15_in_data_valid_reg_stage2;
    reg  [DATA_OUT_WIDTH-1:0]    q31_out_data_reg_stage2;
    reg                          q31_out_valid_reg_stage2;
    reg                          q31_out_ready_buf3;

    // Buffer for b0 signal (magnitude[0])
    reg                          b0_buf1;
    reg                          b0_buf2;

    // Buffered q31_out_ready for fanout reduction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q31_out_ready_buf1 <= 1'b0;
            q31_out_ready_buf2 <= 1'b0;
            q31_out_ready_buf3 <= 1'b0;
        end else begin
            q31_out_ready_buf1 <= q31_out_ready;
            q31_out_ready_buf2 <= q31_out_ready_buf1;
            q31_out_ready_buf3 <= q31_out_ready_buf2;
        end
    end

    // Input data and valid buffering (two-stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q15_in_data_reg_stage1        <= {DATA_IN_WIDTH{1'b0}};
            q15_in_data_valid_reg_stage1  <= 1'b0;
            q15_in_data_reg_stage2        <= {DATA_IN_WIDTH{1'b0}};
            q15_in_data_valid_reg_stage2  <= 1'b0;
        end else begin
            if (q15_in_ready && q15_in_valid) begin
                q15_in_data_reg_stage1       <= q15_in_data;
                q15_in_data_valid_reg_stage1 <= 1'b1;
            end else if (q31_out_ready_buf3 && q31_out_valid_reg_stage2) begin
                q15_in_data_valid_reg_stage1 <= 1'b0;
            end

            // Stage 2 buffer
            q15_in_data_reg_stage2       <= q15_in_data_reg_stage1;
            q15_in_data_valid_reg_stage2 <= q15_in_data_valid_reg_stage1;
        end
    end

    // Output data and valid buffering (two-stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q31_out_data_reg_stage1  <= {DATA_OUT_WIDTH{1'b0}};
            q31_out_valid_reg_stage1 <= 1'b0;
            q31_out_data_reg_stage2  <= {DATA_OUT_WIDTH{1'b0}};
            q31_out_valid_reg_stage2 <= 1'b0;
        end else begin
            if (q15_in_data_valid_reg_stage2 && 
                (!q31_out_valid_reg_stage2 || (q31_out_ready_buf3 && q31_out_valid_reg_stage2))) begin
                q31_out_data_reg_stage1  <= {q15_in_data_reg_stage2[15], q15_in_data_reg_stage2[14:0], 16'b0};
                q31_out_valid_reg_stage1 <= 1'b1;
            end else if (q31_out_ready_buf3 && q31_out_valid_reg_stage2) begin
                q31_out_valid_reg_stage1 <= 1'b0;
            end

            // Stage 2 buffer
            q31_out_data_reg_stage2  <= q31_out_data_reg_stage1;
            q31_out_valid_reg_stage2 <= q31_out_valid_reg_stage1;
        end
    end

    // Buffer for magnitude[0] (b0)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
        end else begin
            b0_buf1 <= q15_in_data_reg_stage2[0];
            b0_buf2 <= b0_buf1;
        end
    end

    // Output assignments from buffered registers
    assign q15_in_ready  = ~q15_in_data_valid_reg_stage2 || (q31_out_ready_buf3 && q31_out_valid_reg_stage2);
    assign q31_out_data  = q31_out_data_reg_stage2;
    assign q31_out_valid = q31_out_valid_reg_stage2;

endmodule