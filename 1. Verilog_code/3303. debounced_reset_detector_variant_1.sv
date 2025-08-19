//SystemVerilog
module debounced_reset_detector #(parameter DEBOUNCE_CYCLES = 8)(
    input  wire        clock,
    input  wire        external_reset_n,
    input  wire        power_on_reset_n,
    output reg         reset_active,
    output reg  [1:0]  reset_source
);
    reg [3:0] ext_counter = 4'd0;
    reg [3:0] por_counter = 4'd0;

    // External reset debounce counter
    always @(posedge clock) begin
        if (external_reset_n)
            ext_counter <= 4'd0;
        else if (ext_counter != DEBOUNCE_CYCLES && ext_counter != 4'hF)
            ext_counter <= ext_counter + 4'd1;
    end

    // Power-on reset debounce counter
    always @(posedge clock) begin
        if (power_on_reset_n)
            por_counter <= 4'd0;
        else if (por_counter != DEBOUNCE_CYCLES && por_counter != 4'hF)
            por_counter <= por_counter + 4'd1;
    end

    // Reset active logic
    always @(posedge clock) begin
        reset_active <= ((ext_counter >= DEBOUNCE_CYCLES) | (por_counter >= DEBOUNCE_CYCLES));
    end

    // Reset source logic
    always @(posedge clock) begin
        casex ({por_counter >= DEBOUNCE_CYCLES, ext_counter >= DEBOUNCE_CYCLES})
            2'b10: reset_source <= 2'b01;
            2'b01: reset_source <= 2'b10;
            default: reset_source <= 2'b00;
        endcase
    end

endmodule