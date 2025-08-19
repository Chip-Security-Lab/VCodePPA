//SystemVerilog
//IEEE 1364-2005 Verilog
module piso_reg (
    input clk, clear_b, load,
    input [7:0] parallel_in,
    output reg serial_out
);
    reg [6:0] data = 7'h00;
    reg next_serial_out;
    
    // Buffered versions of next_serial_out to reduce fanout
    reg next_serial_out_buf1;
    reg next_serial_out_buf2;
    
    // Pre-compute next serial output value
    always @(*) begin
        casez ({clear_b, load})
            2'b0?: next_serial_out = 1'b0;           // Clear
            2'b11: next_serial_out = parallel_in[7]; // Load MSB from parallel input
            2'b10: next_serial_out = data[6];        // Shift from previous MSB
            default: next_serial_out = serial_out;   // Maintain current state
        endcase
    end
    
    // Buffer registers for high fanout signal
    always @(posedge clk or negedge clear_b) begin
        if (!clear_b) begin
            next_serial_out_buf1 <= 1'b0;
            next_serial_out_buf2 <= 1'b0;
        end
        else begin
            next_serial_out_buf1 <= next_serial_out;
            next_serial_out_buf2 <= next_serial_out;
        end
    end
    
    // Register for serial output - use buffer 1
    always @(posedge clk or negedge clear_b) begin
        if (!clear_b)
            serial_out <= 1'b0;
        else
            serial_out <= next_serial_out_buf1;
    end
    
    // Register for remaining data bits - use buffer 2
    always @(posedge clk or negedge clear_b) begin
        if (!clear_b) begin
            data <= 7'h00;
        end
        else if (load) begin
            data <= parallel_in[6:0];  // Load lower 7 bits
        end
        else begin
            data <= {data[5:0], 1'b0}; // Shift left
        end
    end
endmodule