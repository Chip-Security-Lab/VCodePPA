//SystemVerilog
//-----------------------------------------------------------------------------
// Title       : Variable Shift Register System
// Description : Hierarchical implementation of variable shift register with
//               lookup table-assisted shift operation
// Standard    : IEEE 1364-2005 Verilog
//-----------------------------------------------------------------------------

module var_shift #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire [W-1:0] data,
    input wire [2:0] shift_amt,
    input wire load,
    output wire [W-1:0] result
);
    // Internal signals
    wire [W-1:0] shift_reg_out;
    
    // Control signals to sub-modules
    wire ctrl_load;
    wire ctrl_clear;
    wire [2:0] ctrl_shift_amt;
    
    // Instantiate control module
    shift_controller #(
        .W(W)
    ) u_controller (
        .clock(clock),
        .clear(clear),
        .load(load),
        .shift_amt(shift_amt),
        .ctrl_clear(ctrl_clear),
        .ctrl_load(ctrl_load),
        .ctrl_shift_amt(ctrl_shift_amt)
    );
    
    // Instantiate data path module
    shift_datapath #(
        .W(W)
    ) u_datapath (
        .clock(clock),
        .clear(ctrl_clear),
        .load(ctrl_load),
        .data(data),
        .shift_amt(ctrl_shift_amt),
        .shifted_data(shift_reg_out)
    );
    
    // Assign output
    assign result = shift_reg_out;
    
endmodule

//-----------------------------------------------------------------------------
// Control module for shift operations
//-----------------------------------------------------------------------------
module shift_controller #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire load,
    input wire [2:0] shift_amt,
    output reg ctrl_clear,
    output reg ctrl_load,
    output reg [2:0] ctrl_shift_amt
);
    // Pipeline registers to improve timing
    always @(posedge clock) begin
        ctrl_clear <= clear;
        ctrl_load <= load;
        ctrl_shift_amt <= shift_amt;
    end
    
endmodule

//-----------------------------------------------------------------------------
// Datapath module handling the register and shift operations
// Implemented with lookup-table assisted shift algorithm
//-----------------------------------------------------------------------------
module shift_datapath #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire load,
    input wire [W-1:0] data,
    input wire [2:0] shift_amt,
    output wire [W-1:0] shifted_data
);
    reg [W-1:0] shift_reg;
    reg [W-1:0] shift_result;
    
    // Lookup table for shift amount mapping
    reg [W-1:0] shift_lut [0:7];
    
    // Generate the shift lookup table dynamically
    always @* begin
        integer i;
        for (i = 0; i < 8; i = i + 1) begin
            case (i)
                3'b000: shift_lut[i] = shift_reg;                 // No shift
                3'b001: shift_lut[i] = {1'b0, shift_reg[W-1:1]};  // Shift by 1
                3'b010: shift_lut[i] = {2'b0, shift_reg[W-1:2]};  // Shift by 2
                3'b011: shift_lut[i] = {3'b0, shift_reg[W-1:3]};  // Shift by 3
                3'b100: shift_lut[i] = {4'b0, shift_reg[W-1:4]};  // Shift by 4
                3'b101: shift_lut[i] = {5'b0, shift_reg[W-1:5]};  // Shift by 5
                3'b110: shift_lut[i] = {6'b0, shift_reg[W-1:6]};  // Shift by 6
                3'b111: shift_lut[i] = {7'b0, shift_reg[W-1:7]};  // Shift by 7
            endcase
        end
    end
    
    // Lookup-based shift operation
    always @* begin
        shift_result = shift_lut[shift_amt];
    end
    
    // Register operation with clear and load
    always @(posedge clock) begin
        if (clear)
            shift_reg <= {W{1'b0}};
        else if (load)
            shift_reg <= data;
        else
            shift_reg <= shift_result;
    end
    
    // Output assignment
    assign shifted_data = shift_reg;
    
endmodule