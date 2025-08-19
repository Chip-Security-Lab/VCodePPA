//SystemVerilog
// SystemVerilog - Optimized Asynchronous Pulse Generator
module async_pulse_gen(
    input  logic data_in,   // Input data signal
    input  logic reset,     // Reset signal
    output logic pulse_out  // Output pulse
);
    // Registered version of input data for edge detection
    logic data_delayed;
    
    // Reset handling block
    always_comb begin
        if (reset)
            data_delayed = 1'b0;
        else
            data_delayed = data_in;
    end
    
    // Pulse generation block - detects rising edges
    always_comb begin
        pulse_out = data_in & ~data_delayed;
    end
endmodule