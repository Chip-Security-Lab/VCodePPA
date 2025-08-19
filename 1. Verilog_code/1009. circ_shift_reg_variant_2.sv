//SystemVerilog
module circ_shift_reg #(
    parameter WIDTH = 12
)(
    input                   clk,
    input                   rstn,
    input                   en,
    input                   dir,
    input  [WIDTH-1:0]      load_val,
    input                   load_en,
    output reg [WIDTH-1:0]  shifter_out
);

    // Stage 1: Capture control signals and input data
    reg [WIDTH-1:0] load_val_stage1;
    reg             en_stage1;
    reg             dir_stage1;
    reg             load_en_stage1;
    reg             valid_stage1;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            load_val_stage1   <= {WIDTH{1'b0}};
            en_stage1         <= 1'b0;
            dir_stage1        <= 1'b0;
            load_en_stage1    <= 1'b0;
            valid_stage1      <= 1'b0;
        end else begin
            load_val_stage1   <= load_val;
            en_stage1         <= en;
            dir_stage1        <= dir;
            load_en_stage1    <= load_en;
            valid_stage1      <= 1'b1;
        end
    end

    // Stage 2: Mux for load or shift
    reg [WIDTH-1:0] mux_out_stage2;
    reg             en_stage2;
    reg             dir_stage2;
    reg             valid_stage2;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            mux_out_stage2 <= {WIDTH{1'b0}};
            en_stage2      <= 1'b0;
            dir_stage2     <= 1'b0;
            valid_stage2   <= 1'b0;
        end else if (valid_stage1) begin
            if (load_en_stage1) begin
                mux_out_stage2 <= load_val_stage1;
            end else begin
                mux_out_stage2 <= shifter_out;
            end
            en_stage2    <= en_stage1;
            dir_stage2   <= dir_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            mux_out_stage2 <= shifter_out;
            en_stage2      <= 1'b0;
            dir_stage2     <= 1'b0;
            valid_stage2   <= 1'b0;
        end
    end

    // Stage 3: Compute shift data, split shift logic into two stages for higher frequency
    reg [WIDTH-1:0] shift_left_stage3;
    reg [WIDTH-1:0] shift_right_stage3;
    reg             dir_stage3;
    reg             en_stage3;
    reg [WIDTH-1:0] pre_shift_data_stage3;
    reg             valid_stage3;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shift_left_stage3      <= {WIDTH{1'b0}};
            shift_right_stage3     <= {WIDTH{1'b0}};
            dir_stage3             <= 1'b0;
            en_stage3              <= 1'b0;
            pre_shift_data_stage3  <= {WIDTH{1'b0}};
            valid_stage3           <= 1'b0;
        end else if (valid_stage2) begin
            // Precompute left and right shift results
            shift_left_stage3     <= {mux_out_stage2[WIDTH-2:0], mux_out_stage2[WIDTH-1]};
            shift_right_stage3    <= {mux_out_stage2[0], mux_out_stage2[WIDTH-1:1]};
            dir_stage3            <= dir_stage2;
            en_stage3             <= en_stage2;
            pre_shift_data_stage3 <= mux_out_stage2;
            valid_stage3          <= 1'b1;
        end else begin
            shift_left_stage3      <= shift_left_stage3;
            shift_right_stage3     <= shift_right_stage3;
            dir_stage3             <= 1'b0;
            en_stage3              <= 1'b0;
            pre_shift_data_stage3  <= pre_shift_data_stage3;
            valid_stage3           <= 1'b0;
        end
    end

    // Stage 4: Select shift direction or hold
    reg [WIDTH-1:0] shifter_data_stage4;
    reg             valid_stage4;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shifter_data_stage4 <= {WIDTH{1'b0}};
            valid_stage4        <= 1'b0;
        end else if (valid_stage3) begin
            if (en_stage3) begin
                shifter_data_stage4 <= dir_stage3 ? shift_left_stage3 : shift_right_stage3;
            end else begin
                shifter_data_stage4 <= pre_shift_data_stage3;
            end
            valid_stage4 <= 1'b1;
        end else begin
            shifter_data_stage4 <= shifter_data_stage4;
            valid_stage4        <= 1'b0;
        end
    end

    // Stage 5: Output register
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shifter_out <= {WIDTH{1'b0}};
        end else if (valid_stage4) begin
            shifter_out <= shifter_data_stage4;
        end
    end

endmodule