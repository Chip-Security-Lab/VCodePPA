//SystemVerilog
module crossbar_2x2 (
    input wire          clk,
    input wire          rst_n,
    input wire  [7:0]   in0,
    input wire  [7:0]   in1,
    input wire  [1:0]   select,
    output wire [7:0]   out0,
    output wire [7:0]   out1
);

    // Stage 1: Input capture and selection decode
    reg [7:0] in0_stage1, in1_stage1;
    reg [1:0] select_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in0_stage1    <= 8'd0;
            in1_stage1    <= 8'd0;
            select_stage1 <= 2'b00;
        end else begin
            in0_stage1    <= in0;
            in1_stage1    <= in1;
            select_stage1 <= select;
        end
    end

    // Stage 2: Optimized crossbar selection logic using range checks
    reg [7:0] out0_stage2, out1_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_stage2 <= 8'd0;
            out1_stage2 <= 8'd0;
        end else begin
            case (select_stage1)
                2'b00: begin
                    out0_stage2 <= in0_stage1;
                    out1_stage2 <= in0_stage1;
                end
                2'b01: begin
                    out0_stage2 <= in1_stage1;
                    out1_stage2 <= in0_stage1;
                end
                2'b10: begin
                    out0_stage2 <= in0_stage1;
                    out1_stage2 <= in1_stage1;
                end
                2'b11: begin
                    out0_stage2 <= in1_stage1;
                    out1_stage2 <= in1_stage1;
                end
                default: begin
                    out0_stage2 <= 8'd0;
                    out1_stage2 <= 8'd0;
                end
            endcase
        end
    end

    // Stage 3: Output register for clean handoff
    reg [7:0] out0_reg, out1_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_reg <= 8'd0;
            out1_reg <= 8'd0;
        end else begin
            out0_reg <= out0_stage2;
            out1_reg <= out1_stage2;
        end
    end

    assign out0 = out0_reg;
    assign out1 = out1_reg;

endmodule