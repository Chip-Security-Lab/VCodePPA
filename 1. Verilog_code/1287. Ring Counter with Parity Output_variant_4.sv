//SystemVerilog
module parity_ring_counter(
    input wire clk,
    input wire rst_n,
    input wire ready,        // Ready signal from receiver
    output reg valid,        // Valid signal to receiver
    output reg [3:0] count,
    output reg parity
);
    // Internal signals
    wire next_parity;
    wire [3:0] next_count;
    reg data_transferred;
    
    // Calculate next count value
    assign next_count = {count[2:0], count[3]};
    
    // Calculate parity of next count
    assign next_parity = ^next_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'b0001;
            parity <= 1'b1;  // Parity of 4'b0001 is 1
            valid <= 1'b0;
            data_transferred <= 1'b0;
        end
        else begin
            if (!data_transferred) begin
                // Assert valid when new data is available
                valid <= 1'b1;
                
                // Data transfer occurs when valid and ready are both high
                if (valid && ready) begin
                    count <= next_count;
                    parity <= next_parity;
                    data_transferred <= 1'b1;
                end
            end
            else begin
                // De-assert valid for one cycle after successful transfer
                valid <= 1'b0;
                data_transferred <= 1'b0;
            end
        end
    end
endmodule