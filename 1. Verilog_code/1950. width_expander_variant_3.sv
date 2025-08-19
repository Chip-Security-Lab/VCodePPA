//SystemVerilog
module width_expander #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32  // 必须是IN_WIDTH的整数倍
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [IN_WIDTH-1:0]   data_in,
    output reg  [OUT_WIDTH-1:0]  data_out,
    output reg                   valid_out
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    localparam CNT_WIDTH = $clog2(RATIO);

    // Stage 1 registers
    reg [OUT_WIDTH-1:0]         shift_buffer_stage1;
    reg [CNT_WIDTH-1:0]         input_count_stage1;
    reg                         valid_in_stage1;

    // Stage 2 registers (pipeline cut here)
    reg [OUT_WIDTH-1:0]         shift_buffer_stage2;
    reg [CNT_WIDTH-1:0]         input_count_stage2;
    reg                         valid_in_stage2;

    // Stage 3 registers (final output stage)
    reg [OUT_WIDTH-1:0]         data_out_reg;
    reg                         valid_out_reg;

    // Stage 1: Shift buffer and count update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_buffer_stage1    <= {OUT_WIDTH{1'b0}};
            input_count_stage1     <= {CNT_WIDTH{1'b0}};
            valid_in_stage1        <= 1'b0;
        end else if (valid_in) begin
            shift_buffer_stage1    <= {shift_buffer_stage1[OUT_WIDTH-IN_WIDTH-1:0], data_in};
            input_count_stage1     <= (input_count_stage1 == RATIO-1) ? {CNT_WIDTH{1'b0}} : input_count_stage1 + 1'b1;
            valid_in_stage1        <= 1'b1;
        end else begin
            valid_in_stage1        <= 1'b0;
        end
    end

    // Stage 2: Pipeline register to cut long path
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_buffer_stage2    <= {OUT_WIDTH{1'b0}};
            input_count_stage2     <= {CNT_WIDTH{1'b0}};
            valid_in_stage2        <= 1'b0;
        end else begin
            shift_buffer_stage2    <= shift_buffer_stage1;
            input_count_stage2     <= input_count_stage1;
            valid_in_stage2        <= valid_in_stage1;
        end
    end

    // Stage 3: Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out_reg           <= {OUT_WIDTH{1'b0}};
            valid_out_reg          <= 1'b0;
        end else begin
            if (valid_in_stage2 && (input_count_stage2 == RATIO-1)) begin
                data_out_reg       <= shift_buffer_stage2;
                valid_out_reg      <= 1'b1;
            end else begin
                valid_out_reg      <= 1'b0;
            end
        end
    end

    // Output assignment
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out  <= {OUT_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out  <= data_out_reg;
            valid_out <= valid_out_reg;
        end
    end

endmodule