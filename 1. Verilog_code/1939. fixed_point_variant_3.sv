//SystemVerilog
module fixed_point_pipeline #(parameter Q=4, DW=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire signed [DW-1:0]  in,
    output wire                  valid_out,
    output wire signed [DW-1:0]  out
);

    // Stage 1: Register input
    reg signed [DW-1:0] data_stage1;
    reg                 valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1  <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (start) begin
                data_stage1  <= in;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Shift operation (arithmetic right shift)
    reg signed [DW-1:0] data_stage2;
    reg                 valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2  <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                data_stage2  <= data_stage1 >>> Q;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end

    // Output assignment
    assign out       = data_stage2;
    assign valid_out = valid_stage2;

endmodule