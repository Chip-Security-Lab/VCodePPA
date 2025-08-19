//SystemVerilog
module sync_decim_filter #(
    parameter WIDTH = 8,
    parameter RATIO = 4
)(
    input clock, reset,
    input [WIDTH-1:0] in_data,
    input in_valid,
    output reg [WIDTH-1:0] out_data,
    output reg out_valid
);

    // Internal registers
    reg [$clog2(RATIO)-1:0] counter;
    reg [WIDTH-1:0] sum;
    reg [WIDTH-1:0] next_sum;
    reg [$clog2(RATIO)-1:0] next_counter;
    reg next_out_valid;
    reg [WIDTH-1:0] next_out_data;
    reg [WIDTH-1:0] sum_plus_in;
    reg is_last_count;
    reg [WIDTH-1:0] avg_result;

    // Buffered signals
    reg [WIDTH-1:0] sum_plus_in_buf;
    reg is_last_count_buf;
    reg [WIDTH-1:0] avg_result_buf;

    // Pre-compute common expressions
    always @(*) begin
        sum_plus_in = sum + in_data;
        is_last_count = (counter == RATIO-1);
        avg_result = sum_plus_in / RATIO;
    end

    // Buffer registers for high fanout signals
    always @(posedge clock) begin
        if (reset) begin
            sum_plus_in_buf <= 0;
            is_last_count_buf <= 0;
            avg_result_buf <= 0;
        end else if (in_valid) begin
            sum_plus_in_buf <= sum_plus_in;
            is_last_count_buf <= is_last_count;
            avg_result_buf <= avg_result;
        end
    end

    // Counter logic
    always @(posedge clock) begin
        if (reset) begin
            counter <= 0;
        end else if (in_valid) begin
            counter <= is_last_count_buf ? 0 : counter + 1;
        end
    end

    // Sum accumulation logic
    always @(posedge clock) begin
        if (reset) begin
            sum <= 0;
        end else if (in_valid) begin
            sum <= is_last_count_buf ? 0 : sum_plus_in_buf;
        end
    end

    // Output data and valid signal logic
    always @(posedge clock) begin
        if (reset) begin
            out_data <= 0;
            out_valid <= 0;
        end else if (in_valid) begin
            out_data <= is_last_count_buf ? avg_result_buf : out_data;
            out_valid <= is_last_count_buf;
        end else begin
            out_valid <= 0;
        end
    end

endmodule