//SystemVerilog
module TimeoutMatcher #(parameter WIDTH=8, TIMEOUT=100) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input valid_in,
    output reg valid_out,
    output reg timeout
);

    // Stage 1 registers
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg valid_stage1;
    reg match_stage1;
    
    // Stage 2 registers
    reg [15:0] counter_stage2;
    reg valid_stage2;
    reg match_stage2;
    
    // Stage 3 registers
    reg timeout_stage3;
    reg valid_stage3;

    // LUT for subtraction optimization
    reg [15:0] sub_lut [0:255];
    reg [15:0] sub_result;
    reg [7:0] sub_addr;
    
    // Initialize LUT
    integer i;
    initial begin
        for(i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i;
        end
    end

    // Stage 1: Compare data and pattern with LUT-assisted subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            pattern_stage1 <= 0;
            match_stage1 <= 0;
            valid_stage1 <= 0;
            sub_addr <= 0;
            sub_result <= 0;
        end else begin
            data_stage1 <= data;
            pattern_stage1 <= pattern;
            sub_addr <= data ^ pattern;
            sub_result <= sub_lut[sub_addr];
            match_stage1 <= (sub_result == 0);
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Update counter based on match result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 0;
            match_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            match_stage2 <= match_stage1;
            
            if (valid_stage1) begin
                if (match_stage1) begin
                    counter_stage2 <= 0;
                end else if (counter_stage2 < TIMEOUT) begin
                    counter_stage2 <= counter_stage2 + 1;
                end
            end
        end
    end
    
    // Stage 3: Determine timeout status
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            timeout_stage3 <= (counter_stage2 >= TIMEOUT);
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout <= 0;
            valid_out <= 0;
        end else begin
            timeout <= timeout_stage3;
            valid_out <= valid_stage3;
        end
    end

endmodule