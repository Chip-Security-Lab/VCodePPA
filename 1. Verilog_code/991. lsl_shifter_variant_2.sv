//SystemVerilog
module lsl_shifter_valid_ready (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire [2:0]  shift_amt,
    input  wire        data_in_valid,
    output wire        data_in_ready,
    output reg  [7:0]  data_out,
    output reg         data_out_valid,
    input  wire        data_out_ready
);

    // Internal pipeline stage registers
    reg [7:0] shift_result_stage1;
    reg       stage1_valid;
    reg [2:0] shift_amt_stage1;
    reg [7:0] data_in_stage1;

    reg [7:0] shift_result_stage2;
    reg       stage2_valid;

    // Handshake signals
    wire stage1_ready;
    wire stage2_ready;

    // Stage 1 ready if not holding valid data or stage 2 is ready to accept data
    assign stage1_ready = !stage1_valid || stage2_ready;
    assign data_in_ready = stage1_ready;

    // Stage 2 ready if not holding valid data or output is being accepted
    assign stage2_ready = !stage2_valid || (data_out_ready && data_out_valid);

    // Stage 1: Accept input and perform shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_result_stage1 <= 8'b0;
            shift_amt_stage1    <= 3'b0;
            data_in_stage1      <= 8'b0;
            stage1_valid        <= 1'b0;
        end else begin
            if (stage1_ready) begin
                if (data_in_valid) begin
                    shift_result_stage1 <= data_in << shift_amt;
                    shift_amt_stage1    <= shift_amt;
                    data_in_stage1      <= data_in;
                    stage1_valid        <= 1'b1;
                end else begin
                    stage1_valid        <= 1'b0;
                end
            end else begin
                stage1_valid            <= stage1_valid;
            end
        end
    end

    // Stage 2: Pipeline the result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_result_stage2 <= 8'b0;
            stage2_valid        <= 1'b0;
        end else begin
            if (stage2_ready) begin
                if (stage1_valid) begin
                    shift_result_stage2 <= shift_result_stage1;
                    stage2_valid        <= 1'b1;
                end else begin
                    stage2_valid        <= 1'b0;
                end
            end else begin
                stage2_valid            <= stage2_valid;
            end
        end
    end

    // Output stage: Drive output with valid-ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out      <= 8'b0;
            data_out_valid <= 1'b0;
        end else begin
            if (data_out_ready || !data_out_valid) begin
                if (stage2_valid) begin
                    data_out      <= shift_result_stage2;
                    data_out_valid <= 1'b1;
                end else begin
                    data_out_valid <= 1'b0;
                end
            end else begin
                data_out_valid <= data_out_valid;
            end
        end
    end

endmodule