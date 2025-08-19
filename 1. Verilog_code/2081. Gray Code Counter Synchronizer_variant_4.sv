//SystemVerilog
module gray_counter_sync #(parameter WIDTH = 8) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    input wire increment,
    output wire [WIDTH-1:0] sync_count
);
    reg [WIDTH-1:0] bin_counter;
    reg [WIDTH-1:0] next_bin_counter;
    reg [WIDTH-1:0] gray_counter_comb;
    reg [WIDTH-1:0] gray_sync1, gray_sync2;
    reg [WIDTH-1:0] dst_gray_to_bin;
    reg [WIDTH-1:0] gray_counter_reg;

    // Binary counter logic and Gray code combinational calculation
    always @(*) begin
        if (reset) begin
            next_bin_counter = {WIDTH{1'b0}};
            gray_counter_comb = {WIDTH{1'b0}};
        end else if (increment) begin
            next_bin_counter = bin_counter + 1'b1;
            gray_counter_comb = (bin_counter + 1'b1) ^ ((bin_counter + 1'b1) >> 1);
        end else begin
            next_bin_counter = bin_counter;
            gray_counter_comb = bin_counter ^ (bin_counter >> 1);
        end
    end

    // Register after combinational logic (retimed forward)
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            bin_counter <= {WIDTH{1'b0}};
            gray_counter_reg <= {WIDTH{1'b0}};
        end else begin
            bin_counter <= next_bin_counter;
            gray_counter_reg <= gray_counter_comb;
        end
    end

    // Gray code synchronizer
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            gray_sync1 <= {WIDTH{1'b0}};
            gray_sync2 <= {WIDTH{1'b0}};
        end else begin
            gray_sync1 <= gray_counter_reg;
            gray_sync2 <= gray_sync1;
        end
    end

    // Gray to binary conversion in destination domain
    integer idx;
    always @(*) begin
        idx = WIDTH-2;
        dst_gray_to_bin[WIDTH-1] = gray_sync2[WIDTH-1];
        while (idx >= 0) begin
            dst_gray_to_bin[idx] = dst_gray_to_bin[idx+1] ^ gray_sync2[idx];
            idx = idx - 1;
        end
    end

    assign sync_count = dst_gray_to_bin;
endmodule