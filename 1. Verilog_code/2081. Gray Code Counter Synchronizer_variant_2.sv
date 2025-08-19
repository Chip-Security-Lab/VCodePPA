//SystemVerilog
module gray_counter_sync #(parameter WIDTH = 8) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    input wire increment,
    output wire [WIDTH-1:0] sync_count
);

    // Internal registers
    reg [WIDTH-1:0] binary_counter;
    reg [WIDTH-1:0] gray_counter;
    reg [WIDTH-1:0] gray_sync_stage1, gray_sync_stage2;
    reg [WIDTH-1:0] dst_gray_to_bin;

    // Conditional sum adder for binary increment
    function [WIDTH-1:0] conditional_sum_add_one;
        input [WIDTH-1:0] in;
        reg [WIDTH-1:0] sum;
        reg carry;
        integer j;
        begin
            carry = 1'b1;
            for (j = 0; j < WIDTH; j = j + 1) begin
                sum[j] = in[j] ^ carry;
                carry = in[j] & carry;
            end
            conditional_sum_add_one = sum;
        end
    endfunction

    ////////////////////////////////////////////////////////////////////////////////
    // Binary Counter Update Block
    // Handles incrementing the binary counter on src_clk domain
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            binary_counter <= {WIDTH{1'b0}};
        end else if (increment) begin
            binary_counter <= conditional_sum_add_one(binary_counter);
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Gray Counter Generation Block
    // Converts binary counter to Gray code after increment
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            gray_counter <= {WIDTH{1'b0}};
        end else if (increment) begin
            gray_counter <= conditional_sum_add_one(binary_counter) ^ (conditional_sum_add_one(binary_counter) >> 1);
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Gray Code Synchronizer Stage 1
    // Latches gray_counter into first synchronizer stage on dst_clk
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            gray_sync_stage1 <= {WIDTH{1'b0}};
        end else begin
            gray_sync_stage1 <= gray_counter;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Gray Code Synchronizer Stage 2
    // Latches stage 1 value into stage 2 for metastability protection
    ////////////////////////////////////////////////////////////////////////////////
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            gray_sync_stage2 <= {WIDTH{1'b0}};
        end else begin
            gray_sync_stage2 <= gray_sync_stage1;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Gray to Binary Conversion Block
    // Combinational logic for converting synchronized Gray code to binary
    ////////////////////////////////////////////////////////////////////////////////
    integer i;
    always @(*) begin
        dst_gray_to_bin[WIDTH-1] = gray_sync_stage2[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1) begin
            dst_gray_to_bin[i] = dst_gray_to_bin[i+1] ^ gray_sync_stage2[i];
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Output Assignment Block
    ////////////////////////////////////////////////////////////////////////////////
    assign sync_count = dst_gray_to_bin;

endmodule