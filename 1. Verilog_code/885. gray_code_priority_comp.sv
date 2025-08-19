module gray_code_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] binary_priority,
    output reg [$clog2(WIDTH)-1:0] gray_priority,
    output reg valid
);
    // Binary-to-Gray conversion function
    function [$clog2(WIDTH)-1:0] bin2gray;
        input [$clog2(WIDTH)-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_priority <= 0;
            gray_priority <= 0;
            valid <= 0;
        end else begin
            valid <= |data_in;
            binary_priority <= 0;
            
            // Find highest priority bit position
            for (integer i = WIDTH-1; i >= 0; i = i - 1)
                if (data_in[i]) binary_priority <= i[$clog2(WIDTH)-1:0];
                
            // Convert to Gray code
            gray_priority <= bin2gray(binary_priority);
        end
    end
endmodule