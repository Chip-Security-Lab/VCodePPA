//SystemVerilog
module fixed_point #(parameter Q=4, DW=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire signed [DW-1:0]  in,
    output wire signed [DW-1:0]  out
);
    // Stage 1: Input register
    reg signed [DW-1:0] in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_stage1 <= {DW{1'b0}};
        else
            in_stage1 <= in;
    end

    // Stage 2: Arithmetic right shift
    reg signed [DW-1:0] shifted_in_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifted_in_stage2 <= {DW{1'b0}};
        else
            shifted_in_stage2 <= in_stage1 >>> Q;
    end

    // Stage 3: Subtraction pipeline (out = shifted_in - 0)
    reg signed [DW-1:0] sum_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sum_stage3 <= {DW{1'b0}};
        else
            sum_stage3 <= shifted_in_stage2; // subtract zero, so passthrough
    end

    // Output assignment
    assign out = sum_stage3;

endmodule