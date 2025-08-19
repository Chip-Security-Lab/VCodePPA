//SystemVerilog
//-----------------------------------------------------------------------------
// Top level module for the ring counter system
//-----------------------------------------------------------------------------
module ring_counter #(parameter WIDTH = 4) (
    input wire clock, reset, preset,
    output wire [WIDTH-1:0] count
);
    // Control signals from control_unit to shift_register
    wire load_zero;
    wire load_one;
    wire shift_enable;
    
    // Instantiate control unit
    control_unit control_unit_inst (
        .clock(clock),
        .reset(reset),
        .preset(preset),
        .load_zero(load_zero),
        .load_one(load_one),
        .shift_enable(shift_enable)
    );
    
    // Instantiate shift register
    shift_register #(.WIDTH(WIDTH)) shift_register_inst (
        .clock(clock),
        .load_zero(load_zero),
        .load_one(load_one),
        .shift_enable(shift_enable),
        .count(count)
    );
endmodule

//-----------------------------------------------------------------------------
// Control unit module - generates control signals based on inputs
//-----------------------------------------------------------------------------
module control_unit (
    input wire clock, reset, preset,
    output reg load_zero,
    output reg load_one,
    output reg shift_enable
);
    // Reset signal handling - highest priority
    always @(posedge clock) begin
        if (reset)
            load_zero <= 1'b1;
        else
            load_zero <= 1'b0;
    end
    
    // Preset signal handling - second priority
    always @(posedge clock) begin
        if (!reset && preset)
            load_one <= 1'b1;
        else
            load_one <= 1'b0;
    end
    
    // Shift enable control - lowest priority
    always @(posedge clock) begin
        if (!reset && !preset)
            shift_enable <= 1'b1;
        else
            shift_enable <= 1'b0;
    end
endmodule

//-----------------------------------------------------------------------------
// Shift register module - performs the actual counting function
//-----------------------------------------------------------------------------
module shift_register #(parameter WIDTH = 4) (
    input wire clock,
    input wire load_zero,
    input wire load_one,
    input wire shift_enable,
    output wire [WIDTH-1:0] count
);
    reg [WIDTH-1:0] shift_reg;
    
    // Zero loading logic - highest priority
    always @(posedge clock) begin
        if (load_zero)
            shift_reg <= {WIDTH{1'b0}};
    end
    
    // One loading logic - second priority
    always @(posedge clock) begin
        if (!load_zero && load_one)
            shift_reg <= {1'b1, {(WIDTH-1){1'b0}}};
    end
    
    // Shift operation logic - lowest priority
    always @(posedge clock) begin
        if (!load_zero && !load_one && shift_enable)
            shift_reg <= {shift_reg[0], shift_reg[WIDTH-1:1]};
    end
    
    // Output assignment
    assign count = shift_reg;
endmodule