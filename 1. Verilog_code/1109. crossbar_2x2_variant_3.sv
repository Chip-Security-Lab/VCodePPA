//SystemVerilog
module crossbar_2x2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  in0,
    input  wire [7:0]  in1,
    input  wire [1:0]  select,
    output wire [7:0]  out0,
    output wire [7:0]  out1
);

    // Stage 1: Input Register Stage
    reg [7:0] in0_stage1;
    reg [7:0] in1_stage1;
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

    // Stage 2: Crossbar Selection Logic
    reg [7:0] out0_stage2;
    reg [7:0] out1_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_stage2 <= 8'd0;
            out1_stage2 <= 8'd0;
        end else begin
            out0_stage2 <= (select_stage1[0]) ? in1_stage1 : in0_stage1;
            out1_stage2 <= (select_stage1[1]) ? in1_stage1 : in0_stage1;
        end
    end

    // Stage 3: Output Register Stage (Optional, improves timing closure)
    reg [7:0] out0_pipeline;
    reg [7:0] out1_pipeline;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0_pipeline <= 8'd0;
            out1_pipeline <= 8'd0;
        end else begin
            out0_pipeline <= out0_stage2;
            out1_pipeline <= out1_stage2;
        end
    end

    // Assign outputs from final pipeline stage
    assign out0 = out0_pipeline;
    assign out1 = out1_pipeline;

endmodule