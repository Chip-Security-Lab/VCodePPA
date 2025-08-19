//SystemVerilog
module power_on_reset_delay #(parameter DELAY_COUNT = 16'd1000)(
    input  wire clk,
    input  wire external_reset_n,
    output reg  reset_n
);

    reg [15:0] delay_counter = 16'd0;
    reg        power_stable  = 1'b0;

    // Delay counter logic
    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            delay_counter <= 16'd0;
        end else if (!power_stable) begin
            if (delay_counter + 16'd1 >= DELAY_COUNT) begin
                delay_counter <= delay_counter; // Hold value
            end else begin
                delay_counter <= delay_counter + 16'd1;
            end
        end
    end

    // Power stable logic
    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            power_stable <= 1'b0;
        end else if (!power_stable) begin
            if (delay_counter + 16'd1 >= DELAY_COUNT) begin
                power_stable <= 1'b1;
            end
        end
    end

    // Reset output logic
    always @(posedge clk or negedge external_reset_n) begin
        if (!external_reset_n) begin
            reset_n <= 1'b0;
        end else begin
            reset_n <= power_stable;
        end
    end

endmodule