//SystemVerilog
// SystemVerilog
module ResetDetectorAsync (
    input  wire clk,
    input  wire rst_n,
    output reg  reset_detected
);

    reg reset_stage1;
    reg reset_stage2;
    reg reset_stage3;
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;

    // Stage 1: Detect reset asynchronously and generate valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_stage1   <= 1'b1;
            valid_stage1   <= 1'b1;
        end else begin
            reset_stage1   <= 1'b0;
            valid_stage1   <= 1'b1;
        end
    end

    // Stage 2: Pipeline register for reset and valid chain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_stage2   <= 1'b1;
            valid_stage2   <= 1'b1;
        end else begin
            reset_stage2   <= reset_stage1;
            valid_stage2   <= valid_stage1;
        end
    end

    // Stage 3: Additional pipeline to cut long combinational path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_stage3   <= 1'b1;
            valid_stage3   <= 1'b1;
        end else begin
            reset_stage3   <= reset_stage2;
            valid_stage3   <= valid_stage2;
        end
    end

    // Output assign with pipelined valid chain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_detected <= 1'b1;
        else if (valid_stage3)
            reset_detected <= reset_stage3;
    end

endmodule