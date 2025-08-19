//SystemVerilog
module priority_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] high_data, low_data,
    input high_valid, low_valid,
    output reg high_ready, low_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);
    // Pre-compute condition signals
    wire can_accept_new = !out_valid || out_ready;
    wire transaction_complete = out_valid && out_ready;
    
    // Next state logic
    reg next_out_valid;
    reg next_high_ready;
    reg next_low_ready;
    reg [DWIDTH-1:0] next_out_data;
    
    // Compute next state values in parallel
    always @(*) begin
        // Default: maintain current state
        next_out_valid = out_valid;
        next_high_ready = high_ready;
        next_low_ready = low_ready;
        next_out_data = out_data;

        case ({can_accept_new, transaction_complete})
            2'b10: begin // can accept new data
                next_out_data = high_valid ? high_data : low_data;
                next_out_valid = high_valid || low_valid;
                next_high_ready = !next_out_valid;
                next_low_ready = !next_out_valid;
            end
            2'b01: begin // transaction complete
                next_out_valid = 1'b0;
                next_high_ready = 1'b1;
                next_low_ready = 1'b1;
            end
            default: begin // maintain current state
                next_out_valid = out_valid;
                next_high_ready = high_ready;
                next_low_ready = low_ready;
                next_out_data = out_data;
            end
        endcase
    end
    
    // Register updates
    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            high_ready <= 1'b1;
            low_ready <= 1'b1;
            out_data <= {DWIDTH{1'b0}};
        end else begin
            out_valid <= next_out_valid;
            high_ready <= next_high_ready;
            low_ready <= next_low_ready;
            out_data <= next_out_data;
        end
    end
endmodule