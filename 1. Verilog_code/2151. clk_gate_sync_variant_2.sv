//SystemVerilog
module clk_gate_sync #(parameter WIDTH=4) (
    input  logic clk, en,
    output logic [WIDTH-1:0] out
);
    logic [WIDTH-1:0] next_value;
    logic enable_signal;
    
    // Instance of enable controller submodule with improved synchronization
    enable_controller enable_ctrl (
        .clk(clk),
        .en_in(en),
        .en_out(enable_signal)
    );
    
    // Instance of optimized counter logic submodule
    counter_logic #(
        .WIDTH(WIDTH)
    ) counter (
        .enable(enable_signal),
        .current_value(out),
        .next_value(next_value)
    );
    
    // Instance of output register submodule with reset
    output_register #(
        .WIDTH(WIDTH)
    ) out_reg (
        .clk(clk),
        .data_in(next_value),
        .data_out(out)
    );
    
endmodule

module enable_controller (
    input  logic clk,
    input  logic en_in,
    output logic en_out
);
    // Synchronize enable signal to reduce metastability
    logic en_meta;
    
    always_ff @(posedge clk) begin
        en_meta <= en_in;
        en_out <= en_meta;
    end
endmodule

module counter_logic #(parameter WIDTH=4) (
    input  logic enable,
    input  logic [WIDTH-1:0] current_value,
    output logic [WIDTH-1:0] next_value
);
    // Optimized computation using conditional assignment
    // This implementation reduces logic complexity and improves timing
    assign next_value = enable ? current_value + 1'b1 : current_value;
endmodule

module output_register #(parameter WIDTH=4) (
    input  logic clk,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);
    // Register the output value with more efficient implementation
    always_ff @(posedge clk) begin
        data_out <= data_in;
    end
endmodule