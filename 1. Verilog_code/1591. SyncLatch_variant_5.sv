//SystemVerilog
module SyncLatch #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    // Pipeline registers
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] data_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            data_stage1 <= d;
            valid_stage1 <= en;
        end
    end
    
    // Stage 2: Data processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 0;
        else if (valid_stage2)
            q <= data_stage2;
    end

endmodule