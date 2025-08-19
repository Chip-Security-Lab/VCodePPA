//SystemVerilog
module bit_shuffler #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     data_in,
    input  [1:0]           shuffle_mode,
    output [WIDTH-1:0]     data_out
);

    // Pipeline Stage 1: Input Registration
    reg [WIDTH-1:0] reg_data_in_stage1;
    reg [1:0]       reg_shuffle_mode_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_in_stage1      <= {WIDTH{1'b0}};
            reg_shuffle_mode_stage1 <= 2'b00;
        end else begin
            reg_data_in_stage1      <= data_in;
            reg_shuffle_mode_stage1 <= shuffle_mode;
        end
    end

    // Pipeline Stage 2A: Shuffle Preparation - First part
    reg [WIDTH-1:0] reg_shuffle_prep1_stage2;
    reg [WIDTH-1:0] reg_shuffle_prep2_stage2;
    reg [WIDTH-1:0] reg_shuffle_prep3_stage2;
    reg [WIDTH-1:0] reg_shuffle_prep4_stage2;
    reg [1:0]       reg_shuffle_mode_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_shuffle_prep1_stage2 <= {WIDTH{1'b0}};
            reg_shuffle_prep2_stage2 <= {WIDTH{1'b0}};
            reg_shuffle_prep3_stage2 <= {WIDTH{1'b0}};
            reg_shuffle_prep4_stage2 <= {WIDTH{1'b0}};
            reg_shuffle_mode_stage2  <= 2'b00;
        end else begin
            reg_shuffle_prep1_stage2 <= reg_data_in_stage1;
            reg_shuffle_prep2_stage2 <= reg_data_in_stage1[3:0];
            reg_shuffle_prep3_stage2 <= reg_data_in_stage1[1:0];
            reg_shuffle_prep4_stage2 <= reg_data_in_stage1[5:0];
            reg_shuffle_mode_stage2  <= reg_shuffle_mode_stage1;
        end
    end

    // Pipeline Stage 2B: Shuffle Preparation - Second part
    reg [WIDTH-1:0] reg_shuffle_result0_stage3;
    reg [WIDTH-1:0] reg_shuffle_result1_stage3;
    reg [WIDTH-1:0] reg_shuffle_result2_stage3;
    reg [WIDTH-1:0] reg_shuffle_result3_stage3;
    reg [1:0]       reg_shuffle_mode_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_shuffle_result0_stage3 <= {WIDTH{1'b0}};
            reg_shuffle_result1_stage3 <= {WIDTH{1'b0}};
            reg_shuffle_result2_stage3 <= {WIDTH{1'b0}};
            reg_shuffle_result3_stage3 <= {WIDTH{1'b0}};
            reg_shuffle_mode_stage3    <= 2'b00;
        end else begin
            // Shuffle 0: passthrough
            reg_shuffle_result0_stage3 <= reg_shuffle_prep1_stage2;
            // Shuffle 1: swap upper/lower nibbles
            reg_shuffle_result1_stage3 <= {reg_shuffle_prep2_stage2, reg_shuffle_prep1_stage2[7:4]};
            // Shuffle 2: rotate right by 2
            reg_shuffle_result2_stage3 <= {reg_shuffle_prep3_stage2, reg_shuffle_prep1_stage2[7:2]};
            // Shuffle 3: rotate left by 2
            reg_shuffle_result3_stage3 <= {reg_shuffle_prep1_stage2[7:6], reg_shuffle_prep4_stage2};
            reg_shuffle_mode_stage3    <= reg_shuffle_mode_stage2;
        end
    end

    // Pipeline Stage 3: Output Mux (new Stage 4)
    reg [WIDTH-1:0] reg_data_out_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_out_stage4 <= {WIDTH{1'b0}};
        end else begin
            case (reg_shuffle_mode_stage3)
                2'b00: reg_data_out_stage4 <= reg_shuffle_result0_stage3;
                2'b01: reg_data_out_stage4 <= reg_shuffle_result1_stage3;
                2'b10: reg_data_out_stage4 <= reg_shuffle_result2_stage3;
                2'b11: reg_data_out_stage4 <= reg_shuffle_result3_stage3;
                default: reg_data_out_stage4 <= {WIDTH{1'b0}};
            endcase
        end
    end

    assign data_out = reg_data_out_stage4;

endmodule