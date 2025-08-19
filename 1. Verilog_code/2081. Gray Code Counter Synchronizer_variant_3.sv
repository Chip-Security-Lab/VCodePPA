//SystemVerilog
module gray_counter_sync #(parameter WIDTH = 8) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    input wire increment,
    output wire [WIDTH-1:0] sync_count
);

    reg [WIDTH-1:0] bin_counter_d, bin_counter_q;
    reg [WIDTH-1:0] gray_counter_d, gray_counter_q;
    reg [WIDTH-1:0] gray_sync1_q, gray_sync2_q;
    reg [WIDTH-1:0] dst_gray_to_bin_d, dst_gray_to_bin_q;

    integer i;

    // Move register after combinational logic: update bin_counter and gray_counter via d/q pairs
    always @(*) begin
        if (reset) begin
            bin_counter_d = {WIDTH{1'b0}};
            gray_counter_d = {WIDTH{1'b0}};
        end else if (increment) begin
            bin_counter_d = bin_counter_q + 1'b1;
            gray_counter_d = (bin_counter_q + 1'b1) ^ ((bin_counter_q + 1'b1) >> 1);
        end else begin
            bin_counter_d = bin_counter_q;
            gray_counter_d = gray_counter_q;
        end
    end

    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            bin_counter_q <= {WIDTH{1'b0}};
            gray_counter_q <= {WIDTH{1'b0}};
        end else begin
            bin_counter_q <= bin_counter_d;
            gray_counter_q <= gray_counter_d;
        end
    end

    // Gray code synchronizer, unchanged
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            gray_sync1_q <= {WIDTH{1'b0}};
            gray_sync2_q <= {WIDTH{1'b0}};
        end else begin
            gray_sync1_q <= gray_counter_q;
            gray_sync2_q <= gray_sync1_q;
        end
    end

    // Move register after combinational logic: gray to binary conversion with d/q pairs
    always @(*) begin
        dst_gray_to_bin_d[WIDTH-1] = gray_sync2_q[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1) begin
            dst_gray_to_bin_d[i] = dst_gray_to_bin_d[i+1] ^ gray_sync2_q[i];
        end
    end

    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            dst_gray_to_bin_q <= {WIDTH{1'b0}};
        end else begin
            dst_gray_to_bin_q <= dst_gray_to_bin_d;
        end
    end

    assign sync_count = dst_gray_to_bin_q;

endmodule