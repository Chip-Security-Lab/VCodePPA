//SystemVerilog
module conditional_buffer (
    input wire clk,
    input wire rst_n,
    
    // Input interface with valid signal
    input wire [7:0] data_in,
    input wire [7:0] threshold,
    input wire valid_in,
    output reg ready_in,
    
    // Output interface with valid-ready handshake
    output reg [7:0] data_out,
    output reg valid_out,
    input wire ready_out
);

    // Internal buffer for storing data
    reg [7:0] data_buffer;
    reg buffer_valid;
    
    // Combined input-output handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;
            buffer_valid <= 1'b0;
            data_buffer <= 8'h0;
            valid_out <= 1'b0;
            data_out <= 8'h0;
        end else begin
            // Input logic
            if (valid_in && ready_in && (data_in > threshold)) begin
                data_buffer <= data_in;
                buffer_valid <= 1'b1;
                ready_in <= 1'b0;
            end
            
            // Output logic
            if (buffer_valid && !valid_out) begin
                data_out <= data_buffer;
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                if (buffer_valid) begin
                    buffer_valid <= 1'b0;
                    ready_in <= 1'b1;
                end
            end
        end
    end
    
endmodule