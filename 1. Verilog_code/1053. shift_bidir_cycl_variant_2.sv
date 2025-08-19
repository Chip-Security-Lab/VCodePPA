//SystemVerilog
module shift_bidir_cycl_pipeline #(parameter WIDTH=8) (
    input                   clk,
    input                   rst_n,
    input                   dir,
    input                   en,
    input  [WIDTH-1:0]      data_in,
    output reg [WIDTH-1:0]  data_out,
    output reg              valid_out
);

// Stage 1: Input latch and decode
reg [WIDTH-1:0] data_in_stage1;
reg             dir_stage1;
reg             en_stage1;
reg             valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_stage1 <= {WIDTH{1'b0}};
        dir_stage1     <= 1'b0;
        en_stage1      <= 1'b0;
        valid_stage1   <= 1'b0;
    end else begin
        data_in_stage1 <= data_in;
        dir_stage1     <= dir;
        en_stage1      <= en;
        valid_stage1   <= en;
    end
end

// Stage 2: Shift and preparation
reg [WIDTH-1:0] left_shifted_stage2;
reg [WIDTH-1:0] right_shifted_stage2;
reg [WIDTH-1:0] subtrahend_stage2;
reg [WIDTH-1:0] minuend_stage2;
reg             dir_stage2;
reg             en_stage2;
reg             valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        left_shifted_stage2   <= {WIDTH{1'b0}};
        right_shifted_stage2  <= {WIDTH{1'b0}};
        subtrahend_stage2     <= {WIDTH{1'b0}};
        minuend_stage2        <= {WIDTH{1'b0}};
        dir_stage2            <= 1'b0;
        en_stage2             <= 1'b0;
        valid_stage2          <= 1'b0;
    end else begin
        left_shifted_stage2   <= {data_in_stage1[WIDTH-2:0], data_in_stage1[WIDTH-1]};
        right_shifted_stage2  <= {data_in_stage1[0], data_in_stage1[WIDTH-1:1]};
        subtrahend_stage2     <= {data_in_stage1[WIDTH-2:0], data_in_stage1[WIDTH-1]};
        minuend_stage2        <= data_in_stage1;
        dir_stage2            <= dir_stage1;
        en_stage2             <= en_stage1;
        valid_stage2          <= valid_stage1;
    end
end

// Stage 3: Compute twos complement and final output selection
reg [WIDTH-1:0] subtrahend_inverted_stage3;
reg [WIDTH-1:0] minuend_stage3;
reg [WIDTH-1:0] right_shifted_stage3;
reg             dir_stage3;
reg             en_stage3;
reg             valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        subtrahend_inverted_stage3 <= {WIDTH{1'b0}};
        minuend_stage3             <= {WIDTH{1'b0}};
        right_shifted_stage3       <= {WIDTH{1'b0}};
        dir_stage3                 <= 1'b0;
        en_stage3                  <= 1'b0;
        valid_stage3               <= 1'b0;
    end else begin
        subtrahend_inverted_stage3 <= ~subtrahend_stage2;
        minuend_stage3             <= minuend_stage2;
        right_shifted_stage3       <= right_shifted_stage2;
        dir_stage3                 <= dir_stage2;
        en_stage3                  <= en_stage2;
        valid_stage3               <= valid_stage2;
    end
end

// Stage 4: Final computation and output register
reg [WIDTH-1:0] twos_complement_sum_stage4;
reg             carry_out_stage4;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        twos_complement_sum_stage4 <= {WIDTH{1'b0}};
        carry_out_stage4           <= 1'b0;
    end else begin
        {carry_out_stage4, twos_complement_sum_stage4} <= minuend_stage3 + subtrahend_inverted_stage3 + 1'b1;
    end
end

// Stage 5: Output selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out  <= {WIDTH{1'b0}};
        valid_out <= 1'b0;
    end else begin
        if (en_stage3 && valid_stage3) begin
            if (dir_stage3) begin
                data_out <= right_shifted_stage3;
            end else begin
                data_out <= twos_complement_sum_stage4;
            end
            valid_out <= 1'b1;
        end else begin
            data_out  <= data_out;
            valid_out <= 1'b0;
        end
    end
end

endmodule