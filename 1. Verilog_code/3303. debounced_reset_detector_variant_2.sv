//SystemVerilog
module debounced_reset_detector #(
    parameter DEBOUNCE_CYCLES = 8
)(
    input  wire        clock,
    input  wire        external_reset_n,
    input  wire        power_on_reset_n,
    output reg         reset_active,
    output reg  [1:0]  reset_source
);

    // Debounce counters for external and power-on reset
    reg [3:0] ext_counter = 4'd0;
    reg [3:0] por_counter = 4'd0;

    // Combinational signals for counter conditions
    wire ext_reset_asserted = ~external_reset_n;
    wire por_reset_asserted = ~power_on_reset_n;

    wire ext_counter_max = (ext_counter == DEBOUNCE_CYCLES);
    wire por_counter_max = (por_counter == DEBOUNCE_CYCLES);

    // Next value logic for counters
    wire [3:0] ext_counter_next = external_reset_n         ? 4'd0 :
                                  (!ext_counter_max)        ? ext_counter + 1'b1 :
                                                             ext_counter;

    wire [3:0] por_counter_next = power_on_reset_n         ? 4'd0 :
                                  (!por_counter_max)        ? por_counter + 1'b1 :
                                                             por_counter;

    // ------------------------------------------------------------------------
    // External Reset Debounce Counter Logic
    // ------------------------------------------------------------------------
    always @(posedge clock) begin
        ext_counter <= ext_counter_next;
    end

    // ------------------------------------------------------------------------
    // Power-On Reset Debounce Counter Logic
    // ------------------------------------------------------------------------
    always @(posedge clock) begin
        por_counter <= por_counter_next;
    end

    // ------------------------------------------------------------------------
    // Reset Active Output Logic
    // ------------------------------------------------------------------------
    // Balanced: two independent flag evaluations, then ORed
    reg ext_debounced, por_debounced;
    always @(posedge clock) begin
        ext_debounced <= ext_counter_max;
        por_debounced <= por_counter_max;
        reset_active  <= ext_debounced | por_debounced;
    end

    // ------------------------------------------------------------------------
    // Reset Source Output Logic
    // ------------------------------------------------------------------------
    // Balanced: parallel evaluation, priority logic
    reg [1:0] reset_source_next;
    always @* begin
        if (por_debounced)
            reset_source_next = 2'b01;
        else if (ext_debounced)
            reset_source_next = 2'b10;
        else
            reset_source_next = 2'b00;
    end

    always @(posedge clock) begin
        reset_source <= reset_source_next;
    end

endmodule