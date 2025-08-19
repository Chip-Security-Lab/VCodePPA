//SystemVerilog
module d_latch_preset_clear (
    input wire d,
    input wire enable,
    input wire preset_n,
    input wire clear_n,
    output reg q
);

    // Control logic module
    wire control_enable;
    wire control_preset;
    wire control_clear;
    
    control_logic control_inst (
        .enable(enable),
        .preset_n(preset_n),
        .clear_n(clear_n),
        .control_enable(control_enable),
        .control_preset(control_preset),
        .control_clear(control_clear)
    );

    // Data path module
    data_path data_inst (
        .d(d),
        .control_enable(control_enable),
        .control_preset(control_preset),
        .control_clear(control_clear),
        .q(q)
    );

endmodule

module control_logic (
    input wire enable,
    input wire preset_n,
    input wire clear_n,
    output wire control_enable,
    output wire control_preset,
    output wire control_clear
);
    assign control_enable = enable;
    assign control_preset = !preset_n;
    assign control_clear = !clear_n;
endmodule

module data_path (
    input wire d,
    input wire control_enable,
    input wire control_preset,
    input wire control_clear,
    output reg q
);
    reg [1:0] control_state;
    
    always @* begin
        // Encode control signals into a state
        control_state = {control_preset, control_clear};
        
        case (control_state)
            2'b01: q = 1'b0;  // Clear active
            2'b10: q = 1'b1;  // Preset active
            2'b00: q = control_enable ? d : q;  // Normal operation
            default: q = q;  // Hold current value
        endcase
    end
endmodule