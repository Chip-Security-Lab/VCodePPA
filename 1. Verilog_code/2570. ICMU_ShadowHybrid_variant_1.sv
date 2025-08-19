//SystemVerilog
// Top level module
module ICMU_ShadowHybrid #(
    parameter DW = 32,
    parameter SHADOW_DEPTH = 4
)(
    input clk,
    input shadow_switch,
    input [DW-1:0] reg_in,
    output [DW-1:0] reg_out
);

    wire [1:0] ptr_diff;
    wire [1:0] shadow_ptr;
    wire [DW-1:0] main_reg_out;
    wire [DW-1:0] shadow_reg_out;

    // Main register module
    main_register #(
        .DW(DW)
    ) main_reg_inst (
        .clk(clk),
        .shadow_switch(shadow_switch),
        .reg_in(reg_in),
        .reg_out(main_reg_out)
    );

    // Shadow pointer calculator module
    shadow_pointer_calc shadow_ptr_calc_inst (
        .clk(clk),
        .shadow_switch(shadow_switch),
        .ptr_diff(ptr_diff),
        .shadow_ptr(shadow_ptr)
    );

    // Shadow register array module
    shadow_register_array #(
        .DW(DW),
        .SHADOW_DEPTH(SHADOW_DEPTH)
    ) shadow_reg_array_inst (
        .clk(clk),
        .shadow_switch(shadow_switch),
        .shadow_ptr(shadow_ptr),
        .main_reg(main_reg_out),
        .shadow_reg_out(shadow_reg_out)
    );

    // Output multiplexer
    assign reg_out = shadow_switch ? shadow_reg_out : main_reg_out;

endmodule

// Main register module
module main_register #(
    parameter DW = 32
)(
    input clk,
    input shadow_switch,
    input [DW-1:0] reg_in,
    output reg [DW-1:0] reg_out
);

    always @(posedge clk) begin
        reg_out <= reg_in;
    end

endmodule

// Shadow pointer calculator module
module shadow_pointer_calc(
    input clk,
    input shadow_switch,
    output reg [1:0] shadow_ptr,
    output [1:0] ptr_diff
);

    wire [1:0] ptr_borrow;
    wire [1:0] ptr_propagate;
    wire [1:0] ptr_generate;

    // Parallel prefix subtractor implementation
    assign ptr_generate[0] = ~shadow_ptr[0];
    assign ptr_propagate[0] = shadow_ptr[0];
    assign ptr_borrow[0] = ptr_generate[0];
    
    assign ptr_generate[1] = ~shadow_ptr[1] & ptr_propagate[0];
    assign ptr_propagate[1] = shadow_ptr[1] & ptr_propagate[0];
    assign ptr_borrow[1] = ptr_generate[1] | (ptr_propagate[1] & ptr_borrow[0]);
    
    assign ptr_diff[0] = shadow_ptr[0] ^ ptr_borrow[0];
    assign ptr_diff[1] = shadow_ptr[1] ^ ptr_borrow[1];

    always @(posedge clk) begin
        if (shadow_switch) begin
            shadow_ptr <= ptr_diff + 1'b1;
        end
    end

endmodule

// Shadow register array module
module shadow_register_array #(
    parameter DW = 32,
    parameter SHADOW_DEPTH = 4
)(
    input clk,
    input shadow_switch,
    input [1:0] shadow_ptr,
    input [DW-1:0] main_reg,
    output [DW-1:0] shadow_reg_out
);

    reg [DW-1:0] shadow_regs [0:SHADOW_DEPTH-1];

    always @(posedge clk) begin
        if (shadow_switch) begin
            shadow_regs[shadow_ptr] <= main_reg;
        end
    end

    assign shadow_reg_out = shadow_regs[shadow_ptr];

endmodule