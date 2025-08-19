//SystemVerilog
module shadow_buffer (
    input wire clk,
    input wire [31:0] data_in,
    input wire valid_in,
    output wire ready_in,
    input wire ready_out,
    output reg valid_out,
    output reg [31:0] data_out
);
    reg [31:0] shadow;
    reg data_captured;
    
    // Input handshake and data capture logic
    always @(posedge clk) begin
        if (valid_in && ready_in) begin
            shadow <= data_in;
            data_captured <= 1'b1;
        end else if (valid_out && ready_out) begin
            data_captured <= 1'b0;
        end
    end
    
    // Output handshake logic - simplified state tracking
    always @(posedge clk) begin
        if (data_captured && !valid_out)
            valid_out <= 1'b1;
        else if (valid_out && ready_out)
            valid_out <= 1'b0;
    end
    
    // Data output transfer - combined with handshake logic for better timing
    always @(posedge clk) begin
        if (data_captured && !valid_out)
            data_out <= shadow;
    end
    
    // Combinational ready signal for improved throughput
    assign ready_in = !data_captured || (valid_out && ready_out);
endmodule