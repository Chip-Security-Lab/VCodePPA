//SystemVerilog
// Top-level debounced reset detector, hierarchically organized
module debounced_reset_detector #(
    parameter DEBOUNCE_CYCLES = 8
)(
    input  wire        clock,
    input  wire        external_reset_n,
    input  wire        power_on_reset_n,
    output wire        reset_active,
    output wire [1:0]  reset_source
);

    // Internal debounced signal outputs
    wire ext_reset_debounced;
    wire por_reset_debounced;

    // Debounce power-on reset signal
    debounce_unit #(
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
    ) u_debounce_por (
        .clk       (clock),
        .reset_n   (power_on_reset_n),
        .debounced (por_reset_debounced)
    );

    // Debounce external reset signal
    debounce_unit #(
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
    ) u_debounce_ext (
        .clk       (clock),
        .reset_n   (external_reset_n),
        .debounced (ext_reset_debounced)
    );

    // Determine reset status and source
    reset_status_select u_reset_status (
        .clk                (clock),
        .por_debounced      (por_reset_debounced),
        .ext_debounced      (ext_reset_debounced),
        .reset_active       (reset_active),
        .reset_source       (reset_source)
    );

endmodule

// ---------------------------------------------------------------------------
// Debounce Unit: Generates a debounced pulse for an active-low reset input
// ---------------------------------------------------------------------------
module debounce_unit #(
    parameter DEBOUNCE_CYCLES = 8
)(
    input  wire clk,
    input  wire reset_n,          // Active-low asynchronous reset input
    output reg  debounced         // High when input held low for DEBOUNCE_CYCLES clocks
);

    reg [$clog2(DEBOUNCE_CYCLES+1)-1:0] counter;

    always @(posedge clk) begin
        if (reset_n) begin
            counter   <= 0;
            debounced <= 1'b0;
        end else if (counter == DEBOUNCE_CYCLES) begin
            counter   <= counter;
            debounced <= 1'b1;
        end else begin
            counter   <= counter + 1'b1;
            debounced <= 1'b0;
        end
    end

endmodule

// ---------------------------------------------------------------------------
// Reset Status Selector: Combines debounced reset sources to output status
// ---------------------------------------------------------------------------
module reset_status_select(
    input  wire clk,
    input  wire por_debounced,        // Power-on reset debounced (active high)
    input  wire ext_debounced,        // External reset debounced (active high)
    output reg  reset_active,         // High if any reset source is active
    output reg [1:0] reset_source     // 2'b01: Power-on, 2'b10: External, 2'b00: None
);

    always @(posedge clk) begin
        reset_active <= por_debounced | ext_debounced;
        case (1'b1)
            por_debounced: reset_source <= 2'b01;
            ext_debounced: reset_source <= 2'b10;
            default:       reset_source <= 2'b00;
        endcase
    end

endmodule