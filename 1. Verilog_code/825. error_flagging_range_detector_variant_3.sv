//SystemVerilog
module error_flagging_range_detector(
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [31:0] lower_lim, upper_lim,
    input wire valid_in,         // New input: indicates input data is valid
    output wire ready_in,        // New output: indicates module is ready to accept input
    output reg in_range,
    output reg error_flag,       // Flags invalid range where upper < lower
    output reg valid_out,        // New output: indicates output data is valid
    input wire ready_out         // New input: indicates downstream is ready to accept output
);
    // Internal signals
    wire valid_range = (upper_lim >= lower_lim);
    wire in_bounds = (data_in >= lower_lim) && (data_in <= upper_lim);
    
    // Handshake logic
    reg busy;
    wire handshake_in = valid_in && ready_in;
    wire handshake_out = valid_out && ready_out;
    
    // Ready signal generation - ready when not busy or when completing a transaction
    assign ready_in = !busy || handshake_out;
    
    always @(posedge clk) begin
        if (rst) begin
            in_range <= 1'b0;
            error_flag <= 1'b0;
            valid_out <= 1'b0;
            busy <= 1'b0;
        end
        else begin
            // Clear valid_out when handshake completes
            if (handshake_out)
                valid_out <= 1'b0;
                
            // Process new data when input handshake occurs
            if (handshake_in) begin
                error_flag <= !valid_range;
                in_range <= valid_range && in_bounds;
                valid_out <= 1'b1;  // Output becomes valid
                busy <= 1'b1;       // Module becomes busy
            end
            
            // Clear busy state when output handshake completes
            if (handshake_out)
                busy <= 1'b0;
        end
    end
endmodule