//SystemVerilog
module mux4to1_pipeline (
    input wire              clk,
    input wire              rst_n,
    input wire [1:0]        sel,         // 2-bit selection lines
    input wire [7:0]        in0,
    input wire [7:0]        in1,
    input wire [7:0]        in2,
    input wire [7:0]        in3,
    output reg [7:0]        data_out     // Output data
);

    // Pipeline Stage 1: Input Registration
    reg [7:0] in0_stage1, in1_stage1, in2_stage1, in3_stage1;
    reg [1:0] sel_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in0_stage1 <= 8'd0;
            in1_stage1 <= 8'd0;
            in2_stage1 <= 8'd0;
            in3_stage1 <= 8'd0;
            sel_stage1 <= 2'd0;
        end else begin
            in0_stage1 <= in0;
            in1_stage1 <= in1;
            in2_stage1 <= in2;
            in3_stage1 <= in3;
            sel_stage1 <= sel;
        end
    end

    // Pipeline Stage 2: Booth Multiplier Outputs
    wire [7:0] mul_out0_stage2, mul_out1_stage2, mul_out2_stage2, mul_out3_stage2;
    booth_multiplier_8bit_pipeline mul0 (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(in0_stage1),
        .multiplier(8'd1),
        .product(mul_out0_stage2)
    );
    booth_multiplier_8bit_pipeline mul1 (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(in1_stage1),
        .multiplier(8'd1),
        .product(mul_out1_stage2)
    );
    booth_multiplier_8bit_pipeline mul2 (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(in2_stage1),
        .multiplier(8'd1),
        .product(mul_out2_stage2)
    );
    booth_multiplier_8bit_pipeline mul3 (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(in3_stage1),
        .multiplier(8'd1),
        .product(mul_out3_stage2)
    );

    // Pipeline Stage 3: Output Selection Registration
    reg [7:0] muxed_data_stage3;
    reg [1:0] sel_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            muxed_data_stage3 <= 8'd0;
            sel_stage3 <= 2'd0;
        end else begin
            case (sel_stage1)
                2'b00: muxed_data_stage3 <= mul_out0_stage2;
                2'b01: muxed_data_stage3 <= mul_out1_stage2;
                2'b10: muxed_data_stage3 <= mul_out2_stage2;
                2'b11: muxed_data_stage3 <= mul_out3_stage2;
                default: muxed_data_stage3 <= 8'd0;
            endcase
            sel_stage3 <= sel_stage1;
        end
    end

    // Pipeline Stage 4: Output Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'd0;
        else
            data_out <= muxed_data_stage3;
    end

endmodule

// Booth Multiplier - 8bit Pipeline Version
module booth_multiplier_8bit_pipeline (
    input wire          clk,
    input wire          rst_n,
    input wire  [7:0]   multiplicand,
    input wire  [7:0]   multiplier,
    output reg  [7:0]   product
);

    // Stage 1: Register Inputs
    reg [7:0] multiplicand_reg, multiplier_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_reg <= 8'd0;
            multiplier_reg   <= 8'd0;
        end else begin
            multiplicand_reg <= multiplicand;
            multiplier_reg   <= multiplier;
        end
    end

    // Stage 2: Booth Algorithm Execution
    // For this case, since multiplier is always 1, we simplify the pipeline.
    // But to keep the structure modular, we keep the pipeline stage.
    reg [15:0] booth_accu_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_accu_stage2 <= 16'd0;
        end else begin
            booth_accu_stage2 <= booth_algorithm(multiplicand_reg, multiplier_reg);
        end
    end

    // Stage 3: Output Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            product <= 8'd0;
        else
            product <= booth_accu_stage2[7:0];
    end

    // Booth Algorithm Function (Combinational, called in pipeline)
    function [15:0] booth_algorithm;
        input [7:0] M;
        input [7:0] Q;
        reg   [15:0] acc;
        reg   [8:0]  Qext;
        reg          sign;
        integer      i;
        begin
            acc  = 16'd0;
            Qext = {Q, 1'b0};
            sign = 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                case (Qext[1:0])
                    2'b01: acc[15:8] = acc[15:8] + M;
                    2'b10: acc[15:8] = acc[15:8] - M;
                    default: ;
                endcase
                sign = acc[15];
                acc = {sign, acc[15:1]};
                Qext = {acc[8], Qext[8:1]};
            end
            booth_algorithm = acc;
        end
    endfunction

endmodule