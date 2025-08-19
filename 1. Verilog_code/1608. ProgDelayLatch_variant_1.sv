//SystemVerilog
module ProgDelayLatch #(parameter DW=8) (
    input clk,
    input rst_n,
    input valid_in,
    input [DW-1:0] din,
    input [3:0] delay,
    output reg valid_out,
    output reg [DW-1:0] dout
);

// Pipeline control signals
reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
reg [3:0] delay_stage1, delay_stage2, delay_stage3, delay_stage4;

// Stage 1: First 4 delay elements
reg [DW-1:0] delay_line_stage1 [0:3];
reg [DW-1:0] stage1_out;

// Stage 2: Next 4 delay elements
reg [DW-1:0] delay_line_stage2 [0:3];
reg [DW-1:0] stage2_out;

// Stage 3: Next 4 delay elements
reg [DW-1:0] delay_line_stage3 [0:3];
reg [DW-1:0] stage3_out;

// Stage 4: Final 4 delay elements
reg [DW-1:0] delay_line_stage4 [0:3];
reg [DW-1:0] stage4_out;

// Pipeline control logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
        valid_stage2 <= 1'b0;
        valid_stage3 <= 1'b0;
        valid_stage4 <= 1'b0;
        valid_out <= 1'b0;
    end else begin
        valid_stage1 <= valid_in;
        valid_stage2 <= valid_stage1;
        valid_stage3 <= valid_stage2;
        valid_stage4 <= valid_stage3;
        valid_out <= valid_stage4;
    end
end

// Delay value pipeline
always @(posedge clk) begin
    delay_stage1 <= delay;
    delay_stage2 <= delay_stage1;
    delay_stage3 <= delay_stage2;
    delay_stage4 <= delay_stage3;
end

// Stage 1 pipeline
always @(posedge clk) begin
    if (valid_in) begin
        delay_line_stage1[0] <= din;
        delay_line_stage1[1] <= delay_line_stage1[0];
        delay_line_stage1[2] <= delay_line_stage1[1];
        delay_line_stage1[3] <= delay_line_stage1[2];
        stage1_out <= delay_line_stage1[3];
    end
end

// Stage 2 pipeline
always @(posedge clk) begin
    if (valid_stage1) begin
        delay_line_stage2[0] <= stage1_out;
        delay_line_stage2[1] <= delay_line_stage2[0];
        delay_line_stage2[2] <= delay_line_stage2[1];
        delay_line_stage2[3] <= delay_line_stage2[2];
        stage2_out <= delay_line_stage2[3];
    end
end

// Stage 3 pipeline
always @(posedge clk) begin
    if (valid_stage2) begin
        delay_line_stage3[0] <= stage2_out;
        delay_line_stage3[1] <= delay_line_stage3[0];
        delay_line_stage3[2] <= delay_line_stage3[1];
        delay_line_stage3[3] <= delay_line_stage3[2];
        stage3_out <= delay_line_stage3[3];
    end
end

// Stage 4 pipeline
always @(posedge clk) begin
    if (valid_stage3) begin
        delay_line_stage4[0] <= stage3_out;
        delay_line_stage4[1] <= delay_line_stage4[0];
        delay_line_stage4[2] <= delay_line_stage4[1];
        delay_line_stage4[3] <= delay_line_stage4[2];
        stage4_out <= delay_line_stage4[3];
    end
end

// Output selection based on delayed delay value
always @(posedge clk) begin
    if (valid_stage4) begin
        case(delay_stage4)
            4'd0: dout <= din;
            4'd1: dout <= delay_line_stage1[0];
            4'd2: dout <= delay_line_stage1[1];
            4'd3: dout <= delay_line_stage1[2];
            4'd4: dout <= stage1_out;
            4'd5: dout <= delay_line_stage2[0];
            4'd6: dout <= delay_line_stage2[1];
            4'd7: dout <= delay_line_stage2[2];
            4'd8: dout <= stage2_out;
            4'd9: dout <= delay_line_stage3[0];
            4'd10: dout <= delay_line_stage3[1];
            4'd11: dout <= delay_line_stage3[2];
            4'd12: dout <= stage3_out;
            4'd13: dout <= delay_line_stage4[0];
            4'd14: dout <= delay_line_stage4[1];
            4'd15: dout <= delay_line_stage4[2];
            default: dout <= stage4_out;
        endcase
    end
end

endmodule