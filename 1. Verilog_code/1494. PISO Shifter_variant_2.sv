//SystemVerilog
module piso_shifter (
    input wire clk, clear, load,
    input wire [7:0] parallel_data,
    input wire ack,         // Acknowledge signal (replaces ready)
    output reg req,         // Request signal (replaces valid)
    output wire serial_out
);
    reg [7:0] shift_data;
    reg shift_active;       // Indicates shifting is in progress
    reg load_pending;       // Indicates a load operation is pending
    
    // Control logic for shift operation and handshake
    always @(posedge clk) begin
        if (clear) begin
            shift_data <= 8'h00;
            req <= 1'b0;
            shift_active <= 1'b0;
            load_pending <= 1'b0;
        end
        else if (load) begin
            load_pending <= 1'b1;
        end
        else if (load_pending && !shift_active) begin
            shift_data <= parallel_data;
            req <= 1'b1;             // Assert request when data is loaded
            shift_active <= 1'b1;
            load_pending <= 1'b0;
        end
        else if (shift_active) begin
            if (ack) begin           // When receiver acknowledges
                shift_data <= {shift_data[6:0], 1'b0};
                
                // Check if we've shifted all bits
                if (shift_data[6:0] == 7'b0) begin
                    req <= 1'b0;     // Deassert request when done
                    shift_active <= 1'b0;
                end
            end
        end
    end
    
    assign serial_out = shift_data[7];
endmodule