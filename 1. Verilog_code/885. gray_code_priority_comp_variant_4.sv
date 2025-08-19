//SystemVerilog
module gray_code_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] binary_priority,
    output reg [$clog2(WIDTH)-1:0] gray_priority,
    output reg valid
);

    // Pipeline stage 1: Priority detection
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    reg [$clog2(WIDTH)-1:0] binary_priority_stage1;
    
    // Pipeline stage 2: Gray code conversion
    reg valid_stage2;
    reg [$clog2(WIDTH)-1:0] binary_priority_stage2;
    
    // Binary-to-Gray conversion function
    function [$clog2(WIDTH)-1:0] bin2gray;
        input [$clog2(WIDTH)-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Stage 1: Priority detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
            binary_priority_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= |data_in;
            binary_priority_stage1 <= 0;
            
            for (integer i = WIDTH-1; i >= 0; i = i - 1)
                if (data_in[i]) binary_priority_stage1 <= i[$clog2(WIDTH)-1:0];
        end
    end
    
    // Stage 2: Gray code conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
            binary_priority_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            binary_priority_stage2 <= binary_priority_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_priority <= 0;
            gray_priority <= 0;
            valid <= 0;
        end else begin
            valid <= valid_stage2;
            binary_priority <= binary_priority_stage2;
            gray_priority <= bin2gray(binary_priority_stage2);
        end
    end

endmodule