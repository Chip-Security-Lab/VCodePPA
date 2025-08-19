//SystemVerilog
module ser2par #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire ser_in,
    output reg [WIDTH-1:0] par_out,
    output reg par_out_valid
);

    // Stage 1: Serial input sampling and shift
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [$clog2(WIDTH):0] bit_count_stage1;
    reg en_stage1;
    reg ser_in_stage1;
    reg rst_n_stage1;

    // Stage 2: Bit counting and shift result propagation
    reg [WIDTH-1:0] shift_reg_stage2;
    reg [$clog2(WIDTH):0] bit_count_stage2;
    reg en_stage2;
    reg ser_in_stage2;
    reg rst_n_stage2;
    wire bit_count_is_max_stage2;

    // Stage 3: Output register and valid flag
    reg [WIDTH-1:0] par_out_stage3;
    reg par_out_valid_stage3;

    // Stage 1: Input sampling and shifting
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
            bit_count_stage1 <= {($clog2(WIDTH)+1){1'b0}};
            en_stage1 <= 1'b0;
            ser_in_stage1 <= 1'b0;
            rst_n_stage1 <= 1'b0;
        end else begin
            en_stage1 <= en;
            ser_in_stage1 <= ser_in;
            rst_n_stage1 <= rst_n;
            if (en) begin
                shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], ser_in};
                if (bit_count_stage1 == (WIDTH-1))
                    bit_count_stage1 <= {($clog2(WIDTH)+1){1'b0}};
                else
                    bit_count_stage1 <= bit_count_stage1 + 1'b1;
            end
        end
    end

    // Stage 2: Propagate shift_reg and bit_count, check for output load
    always @(posedge clk or negedge rst_n_stage1) begin
        if (!rst_n_stage1) begin
            shift_reg_stage2 <= {WIDTH{1'b0}};
            bit_count_stage2 <= {($clog2(WIDTH)+1){1'b0}};
            en_stage2 <= 1'b0;
            ser_in_stage2 <= 1'b0;
            rst_n_stage2 <= 1'b0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            bit_count_stage2 <= bit_count_stage1;
            en_stage2 <= en_stage1;
            ser_in_stage2 <= ser_in_stage1;
            rst_n_stage2 <= rst_n_stage1;
        end
    end

    assign bit_count_is_max_stage2 = (bit_count_stage2 == (WIDTH-1));

    // Stage 3: Output register and valid flag
    always @(posedge clk or negedge rst_n_stage2) begin
        if (!rst_n_stage2) begin
            par_out_stage3 <= {WIDTH{1'b0}};
            par_out_valid_stage3 <= 1'b0;
        end else begin
            if (bit_count_is_max_stage2 && en_stage2) begin
                par_out_stage3 <= {shift_reg_stage2[WIDTH-2:0], ser_in_stage2};
                par_out_valid_stage3 <= 1'b1;
            end else begin
                par_out_valid_stage3 <= 1'b0;
            end
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            par_out <= {WIDTH{1'b0}};
            par_out_valid <= 1'b0;
        end else begin
            par_out <= par_out_stage3;
            par_out_valid <= par_out_valid_stage3;
        end
    end

endmodule