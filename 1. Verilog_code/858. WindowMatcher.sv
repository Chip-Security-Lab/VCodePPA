module WindowMatcher #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg match
);
    // Define a sliding window buffer to store incoming data
    reg [WIDTH-1:0] buffer [DEPTH-1:0];
    
    // 使用单独的常量替代SystemVerilog风格的数组初始化
    localparam [WIDTH-1:0] TARGET_PATTERN_0 = 8'hA1;
    localparam [WIDTH-1:0] TARGET_PATTERN_1 = 8'hB2;
    localparam [WIDTH-1:0] TARGET_PATTERN_2 = 8'hC3;
    localparam [WIDTH-1:0] TARGET_PATTERN_3 = 8'hD4;
    
    integer i;
    reg match_found;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset buffer and match signal
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= {WIDTH{1'b0}};
            end
            match <= 1'b0;
        end
        else begin
            // Shift in new data
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer[i] <= buffer[i-1];
            end
            buffer[0] <= data_in;
            
            // 使用if-else结构检查模式匹配
            match_found = 1'b1;
            if (buffer[0] != TARGET_PATTERN_0) match_found = 1'b0;
            if (buffer[1] != TARGET_PATTERN_1) match_found = 1'b0;
            if (buffer[2] != TARGET_PATTERN_2) match_found = 1'b0;
            if (buffer[3] != TARGET_PATTERN_3) match_found = 1'b0;
            
            match <= match_found;
        end
    end
endmodule