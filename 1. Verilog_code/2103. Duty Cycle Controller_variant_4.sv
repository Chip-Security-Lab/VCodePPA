//SystemVerilog
module duty_cycle_controller(
    input wire clock_in,
    input wire reset,
    input wire [3:0] duty_cycle, // 0-15 (0%-93.75%)
    output reg clock_out
);
    reg [3:0] count_reg;
    reg [3:0] count_buf1;
    reg [3:0] count_buf2;

    // Main counter logic
    always @(posedge clock_in) begin
        if (reset) begin
            count_reg <= 4'd0;
        end else begin
            if (count_reg < 4'd15)
                count_reg <= count_reg + 1'b1;
            else
                count_reg <= 4'd0;
        end
    end

    // First stage buffer for count signal
    always @(posedge clock_in) begin
        if (reset) begin
            count_buf1 <= 4'd0;
        end else begin
            count_buf1 <= count_reg;
        end
    end

    // Second stage buffer for count signal
    always @(posedge clock_in) begin
        if (reset) begin
            count_buf2 <= 4'd0;
        end else begin
            count_buf2 <= count_buf1;
        end
    end

    // Output logic using buffered count signal
    always @(posedge clock_in) begin
        if (reset) begin
            clock_out <= 1'b0;
        end else begin
            clock_out <= (count_buf2 < duty_cycle) ? 1'b1 : 1'b0;
        end
    end

endmodule