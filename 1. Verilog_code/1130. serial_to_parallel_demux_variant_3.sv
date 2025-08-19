//SystemVerilog
module serial_to_parallel_demux (
    input wire clk,                      // Clock signal
    input wire rst,                      // Reset signal
    input wire serial_in,                // Serial data input
    input wire load_enable,              // Load control
    output reg [7:0] parallel_out        // Parallel output channels
);
    reg [2:0] bit_counter;               // Bit position counter
    reg [7:0] next_parallel_out;         // Next state for parallel output
    reg serial_in_reg;                   // Registered input data
    reg load_enable_reg;                 // Registered load enable signal
    reg [2:0] bit_counter_reg;           // Pipelined bit counter
    
    // First pipeline stage: Register inputs
    always @(posedge clk) begin
        if (rst) begin
            serial_in_reg <= 1'b0;
            load_enable_reg <= 1'b0;
            bit_counter_reg <= 3'b0;
        end else begin
            serial_in_reg <= serial_in;
            load_enable_reg <= load_enable;
            bit_counter_reg <= bit_counter;
        end
    end
    
    // Second pipeline stage: Generate next state logic with registered inputs
    always @(*) begin
        next_parallel_out = parallel_out;
        if (load_enable_reg && !rst) begin
            next_parallel_out[bit_counter_reg] = serial_in_reg;
        end
    end
    
    // Third pipeline stage: Update bit counter and parallel output
    always @(posedge clk) begin
        if (rst) begin
            bit_counter <= 3'b0;
            parallel_out <= 8'b0;
        end else begin
            parallel_out <= next_parallel_out;
            if (load_enable) begin
                bit_counter <= bit_counter + 1'b1;
            end
        end
    end
endmodule