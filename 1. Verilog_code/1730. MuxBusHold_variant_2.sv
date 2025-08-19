//SystemVerilog
// Top level module
module MuxBusHold #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output [W-1:0] bus_out
);

    wire [W-1:0] selected_bus;

    // Bus selector submodule
    BusSelector #(.W(W)) bus_selector (
        .bus_in(bus_in),
        .sel(sel),
        .hold(hold),
        .selected_bus(selected_bus)
    );

    // Output register submodule  
    OutputRegister #(.W(W)) output_reg (
        .selected_bus(selected_bus),
        .bus_out(bus_out)
    );

endmodule

// Bus selector submodule
module BusSelector #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output reg [W-1:0] selected_bus
);

    always @(*) begin
        if (!hold) begin
            selected_bus = bus_in[sel];
        end
    end

endmodule

// Output register submodule
module OutputRegister #(parameter W=4) (
    input [W-1:0] selected_bus,
    output reg [W-1:0] bus_out
);

    always @(*) begin
        bus_out = selected_bus;
    end

endmodule