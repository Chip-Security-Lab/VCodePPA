//SystemVerilog
// IEEE 1364-2005 Verilog
// Top-level module that coordinates all submodules
module RevCounterShift #(
    parameter N = 4
)(
    input wire clk,
    input wire up_down,
    input wire load,
    input wire [N-1:0] preset,
    output wire [N-1:0] cnt
);
    wire [N-1:0] shifted_data_up;
    wire [N-1:0] shifted_data_down;
    wire [N-1:0] selected_data;
    wire [N-1:0] next_cnt;
    
    // Instantiate shift operations module with LUT-based subtractor
    ShiftOperations #(
        .WIDTH(N)
    ) shift_ops (
        .data_in(cnt),
        .shifted_data_up(shifted_data_up),
        .shifted_data_down(shifted_data_down)
    );
    
    // Instantiate direction selector module
    DirectionSelector #(
        .WIDTH(N)
    ) dir_selector (
        .up_down(up_down),
        .data_up(shifted_data_up),
        .data_down(shifted_data_down),
        .selected_data(selected_data)
    );
    
    // Instantiate load controller module
    LoadController #(
        .WIDTH(N)
    ) load_ctrl (
        .load(load),
        .preset_data(preset),
        .shift_data(selected_data),
        .next_data(next_cnt)
    );
    
    // Instantiate register module
    RegisterBlock #(
        .WIDTH(N)
    ) reg_block (
        .clk(clk),
        .data_in(next_cnt),
        .data_out(cnt)
    );
    
endmodule

// Module for shift operations with LUT-based subtractor
module ShiftOperations #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] shifted_data_up,
    output wire [WIDTH-1:0] shifted_data_down
);
    wire [7:0] subtraction_result;
    
    // Use the subtractor only when WIDTH is at least 8
    generate
        if (WIDTH >= 8) begin: gen_subtractor
            // Instantiate the LUT-assisted subtractor for the first 8 bits
            LUTSubtractor subtractor (
                .a(data_in[7:0]),
                .b(8'h01),  // Subtract 1
                .result(subtraction_result)
            );
        end
    endgenerate
    
    // Rotate left (up) operation
    assign shifted_data_up = {data_in[WIDTH-2:0], data_in[WIDTH-1]};
    
    // Rotate right (down) operation
    // For WIDTH >= 8, we use LUT subtractor result for the lower 8 bits
    generate
        if (WIDTH >= 8) begin: gen_shift_down
            assign shifted_data_down = {data_in[0], data_in[WIDTH-1:WIDTH-7], subtraction_result[0]};
        end else begin
            assign shifted_data_down = {data_in[0], data_in[WIDTH-1:1]};
        end
    endgenerate
    
endmodule

// LUT-Assisted 8-bit Subtractor module
module LUTSubtractor (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] result
);
    // Internal signals
    reg [3:0] lut_lower;
    reg [3:0] lut_upper;
    wire borrow_lower;
    
    // LUT for lower 4-bit subtraction
    always @(*) begin
        case ({a[3:0], b[3:0]})
            // Special optimized cases for common values
            {4'h0, 4'h1}: lut_lower = 4'hF; // 0-1 = F with borrow
            {4'h1, 4'h1}: lut_lower = 4'h0; // 1-1 = 0
            {4'h2, 4'h1}: lut_lower = 4'h1; // 2-1 = 1
            {4'h3, 4'h1}: lut_lower = 4'h2; // 3-1 = 2
            {4'h4, 4'h1}: lut_lower = 4'h3; // 4-1 = 3
            {4'h5, 4'h1}: lut_lower = 4'h4; // 5-1 = 4
            {4'h6, 4'h1}: lut_lower = 4'h5; // 6-1 = 5
            {4'h7, 4'h1}: lut_lower = 4'h6; // 7-1 = 6
            {4'h8, 4'h1}: lut_lower = 4'h7; // 8-1 = 7
            {4'h9, 4'h1}: lut_lower = 4'h8; // 9-1 = 8
            {4'hA, 4'h1}: lut_lower = 4'h9; // A-1 = 9
            {4'hB, 4'h1}: lut_lower = 4'hA; // B-1 = A
            {4'hC, 4'h1}: lut_lower = 4'hB; // C-1 = B
            {4'hD, 4'h1}: lut_lower = 4'hC; // D-1 = C
            {4'hE, 4'h1}: lut_lower = 4'hD; // E-1 = D
            {4'hF, 4'h1}: lut_lower = 4'hE; // F-1 = E
            default: lut_lower = a[3:0] - b[3:0]; // Fallback for other cases
        endcase
    end
    
    // Generate borrow for upper 4 bits
    assign borrow_lower = (a[3:0] < b[3:0]) ? 1'b1 : 1'b0;
    
    // LUT for upper 4-bit subtraction
    always @(*) begin
        if (borrow_lower) begin
            // With borrow from lower 4 bits
            case (a[7:4])
                4'h0: lut_upper = 4'hF; // 0-1 = F
                4'h1: lut_upper = 4'h0; // 1-1 = 0
                4'h2: lut_upper = 4'h1; // 2-1 = 1
                4'h3: lut_upper = 4'h2; // 3-1 = 2
                4'h4: lut_upper = 4'h3; // 4-1 = 3
                4'h5: lut_upper = 4'h4; // 5-1 = 4
                4'h6: lut_upper = 4'h5; // 6-1 = 5
                4'h7: lut_upper = 4'h6; // 7-1 = 6
                4'h8: lut_upper = 4'h7; // 8-1 = 7
                4'h9: lut_upper = 4'h8; // 9-1 = 8
                4'hA: lut_upper = 4'h9; // A-1 = 9
                4'hB: lut_upper = 4'hA; // B-1 = A
                4'hC: lut_upper = 4'hB; // C-1 = B
                4'hD: lut_upper = 4'hC; // D-1 = C
                4'hE: lut_upper = 4'hD; // E-1 = D
                4'hF: lut_upper = 4'hE; // F-1 = E
            endcase
        end else begin
            // Without borrow
            lut_upper = a[7:4] - b[7:4];
        end
    end
    
    // Combine results
    assign result = {lut_upper, lut_lower};
    
endmodule

// Module to select shift direction based on up_down control
module DirectionSelector #(
    parameter WIDTH = 4
)(
    input wire up_down,
    input wire [WIDTH-1:0] data_up,
    input wire [WIDTH-1:0] data_down,
    output wire [WIDTH-1:0] selected_data
);
    // Select between up shift and down shift based on up_down signal
    assign selected_data = up_down ? data_up : data_down;
    
endmodule

// Module to handle load operation
module LoadController #(
    parameter WIDTH = 4
)(
    input wire load,
    input wire [WIDTH-1:0] preset_data,
    input wire [WIDTH-1:0] shift_data,
    output wire [WIDTH-1:0] next_data
);
    // Select between preset data and shifted data based on load signal
    assign next_data = load ? preset_data : shift_data;
    
endmodule

// Module to implement the register with clock
module RegisterBlock #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Register implementation with clock
    always @(posedge clk) begin
        data_out <= data_in;
    end
    
endmodule