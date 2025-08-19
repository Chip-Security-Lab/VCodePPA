//SystemVerilog
// SystemVerilog
module counter_shift_load #(parameter WIDTH=4) (
    input clk, load, shift,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
    // Control signal register
    reg [1:0] ctrl_r;
    // Pipeline registers for data path
    reg [WIDTH-1:0] data_r;
    reg [WIDTH-1:0] shift_data_r;
    
    // First stage: Control logic and data preparation
    always @(posedge clk) begin
        // Register control signals to break timing path
        ctrl_r <= {load, shift};
        // Register input data to break timing path
        data_r <= data;
        // Pre-compute shifted data to reduce critical path
        shift_data_r <= {cnt[WIDTH-2:0], cnt[WIDTH-1]};
    end
    
    // Second stage: Apply control to data path
    always @(posedge clk) begin
        case(ctrl_r)
            2'b10, 2'b11: cnt <= data_r;      // Load operation (higher priority)
            2'b01:        cnt <= shift_data_r; // Shift operation
            2'b00:        cnt <= cnt;         // Hold current value
        endcase
    end
endmodule