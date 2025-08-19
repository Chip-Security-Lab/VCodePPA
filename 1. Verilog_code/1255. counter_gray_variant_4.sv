//SystemVerilog
module counter_gray #(parameter BITS=4) (
    input clk, rst_n, en,
    output reg [BITS-1:0] gray
);
    // Pipeline stage 1: Binary counter
    reg [BITS-1:0] bin_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Gray code conversion
    reg [BITS-1:0] bin_stage2;
    reg valid_stage2;
    
    // Stage 1: Binary counter
    always @(posedge clk) begin
        if (!rst_n) begin
            bin_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= en;
            if (en) begin
                bin_stage1 <= bin_stage1 + 1;
            end
        end
    end
    
    // Stage 2: Register binary value and valid signal
    always @(posedge clk) begin
        if (!rst_n) begin
            bin_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            bin_stage2 <= bin_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Calculate gray code and register the output
    always @(posedge clk) begin
        if (!rst_n) begin
            gray <= 0;
        end else if (valid_stage2) begin
            gray <= bin_stage2 ^ (bin_stage2 >> 1);
        end
    end
endmodule