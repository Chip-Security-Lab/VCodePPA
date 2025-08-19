//SystemVerilog
module shift_reg_with_load (
    input wire clk, reset,
    input wire req_shift, req_load,  // Changed from shift_en, load_en
    output reg ack_shift, ack_load,  // Added acknowledge signals
    input wire serial_in,
    input wire [7:0] parallel_in,
    output wire serial_out,
    output wire [7:0] parallel_out
);
    reg [7:0] shift_reg;
    reg req_shift_r, req_load_r;     // Register request signals
    
    // Detect rising edges of request signals
    always @(posedge clk) begin
        if (reset) begin
            req_shift_r <= 1'b0;
            req_load_r <= 1'b0;
        end else begin
            req_shift_r <= req_shift;
            req_load_r <= req_load;
        end
    end
    
    // Generate acknowledge signals
    always @(posedge clk) begin
        if (reset) begin
            ack_shift <= 1'b0;
            ack_load <= 1'b0;
        end else begin
            // Generate acknowledge when a new request arrives
            ack_shift <= req_shift & ~req_shift_r;
            ack_load <= req_load & ~req_load_r;
        end
    end
    
    // Shift register operation
    always @(posedge clk) begin
        if (reset)
            shift_reg <= 8'h00;
        else if (req_load & ~req_load_r)  // Trigger on rising edge of load request
            shift_reg <= parallel_in;
        else if (req_shift & ~req_shift_r) // Trigger on rising edge of shift request
            shift_reg <= {shift_reg[6:0], serial_in};
    end
    
    assign serial_out = shift_reg[7];
    assign parallel_out = shift_reg;
endmodule