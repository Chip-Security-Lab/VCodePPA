module gray_counter_sync #(parameter WIDTH = 8) (
    input wire src_clk, dst_clk, reset,
    input wire increment,
    output wire [WIDTH-1:0] sync_count
);
    reg [WIDTH-1:0] bin_counter;
    reg [WIDTH-1:0] gray_counter;
    reg [WIDTH-1:0] gray_sync1, gray_sync2;
    reg [WIDTH-1:0] dst_gray_to_bin;
    
    // Binary counter with Gray code output
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            bin_counter <= {WIDTH{1'b0}};
            gray_counter <= {WIDTH{1'b0}};
        end else if (increment) begin
            bin_counter <= bin_counter + 1'b1;
            gray_counter <= bin_counter ^ (bin_counter >> 1);
        end
    end
    
    // Gray code synchronizer
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            gray_sync1 <= {WIDTH{1'b0}};
            gray_sync2 <= {WIDTH{1'b0}};
        end else begin
            gray_sync1 <= gray_counter;
            gray_sync2 <= gray_sync1;
        end
    end
    
    // Gray to binary conversion in destination domain
    integer i;
    always @(*) begin
        dst_gray_to_bin[WIDTH-1] = gray_sync2[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1)
            dst_gray_to_bin[i] = dst_gray_to_bin[i+1] ^ gray_sync2[i];
    end
    
    assign sync_count = dst_gray_to_bin;
endmodule