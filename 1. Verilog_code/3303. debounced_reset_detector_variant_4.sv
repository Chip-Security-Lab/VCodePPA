//SystemVerilog
module debounced_reset_detector #(
    parameter DEBOUNCE_CYCLES = 8
)(
    input clock,
    input external_reset_n,
    input power_on_reset_n,
    output reg reset_active,
    output reg [1:0] reset_source
);
    reg [3:0] ext_counter = 0;
    reg [3:0] por_counter = 0;

    always @(posedge clock) begin
        // External reset debounce counter
        if (external_reset_n) begin
            ext_counter <= 0;
        end else begin
            if (ext_counter == DEBOUNCE_CYCLES) begin
                ext_counter <= DEBOUNCE_CYCLES;
            end else begin
                ext_counter <= ext_counter + 1;
            end
        end

        // Power-on reset debounce counter
        if (power_on_reset_n) begin
            por_counter <= 0;
        end else begin
            if (por_counter == DEBOUNCE_CYCLES) begin
                por_counter <= DEBOUNCE_CYCLES;
            end else begin
                por_counter <= por_counter + 1;
            end
        end

        // Reset active logic
        if ((ext_counter == DEBOUNCE_CYCLES) || (por_counter == DEBOUNCE_CYCLES)) begin
            reset_active <= 1'b1;
        end else begin
            reset_active <= 1'b0;
        end

        // Reset source logic
        if (por_counter == DEBOUNCE_CYCLES) begin
            reset_source <= 2'b01;
        end else if (ext_counter == DEBOUNCE_CYCLES) begin
            reset_source <= 2'b10;
        end else begin
            reset_source <= 2'b00;
        end
    end
endmodule