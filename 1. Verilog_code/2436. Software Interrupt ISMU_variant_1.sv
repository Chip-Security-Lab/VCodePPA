//SystemVerilog
// Top-level module that instantiates submodules
module sw_interrupt_ismu (
    input wire clock,
    input wire reset_n,
    input wire [3:0] hw_int,
    input wire [3:0] sw_int_set,
    input wire [3:0] sw_int_clr,
    output wire [3:0] combined_int
);
    // Internal signals for connecting submodules
    wire [3:0] sw_int;
    
    // Instantiate software interrupt controller
    sw_int_controller sw_ctrl (
        .clock(clock),
        .reset_n(reset_n),
        .sw_int_set(sw_int_set),
        .sw_int_clr(sw_int_clr),
        .sw_int(sw_int)
    );
    
    // Instantiate interrupt combiner
    interrupt_combiner int_combiner (
        .clock(clock),
        .reset_n(reset_n),
        .hw_int(hw_int),
        .sw_int(sw_int),
        .combined_int(combined_int)
    );
    
endmodule

// Software interrupt controller module
module sw_int_controller (
    input wire clock,
    input wire reset_n,
    input wire [3:0] sw_int_set,
    input wire [3:0] sw_int_clr,
    output reg [3:0] sw_int
);
    // SW interrupt register logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            sw_int <= 4'h0;
        end else begin
            sw_int <= (sw_int | sw_int_set) & ~sw_int_clr;
        end
    end
endmodule

// Interrupt combiner module
module interrupt_combiner (
    input wire clock,
    input wire reset_n,
    input wire [3:0] hw_int,
    input wire [3:0] sw_int,
    output reg [3:0] combined_int
);
    // Combined HW and SW interrupts
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            combined_int <= 4'h0;
        end else begin
            combined_int <= hw_int | sw_int;
        end
    end
endmodule