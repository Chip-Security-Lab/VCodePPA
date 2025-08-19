//SystemVerilog
module circular_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire valid_in,
    output reg ready_in,
    output reg [7:0] data_out,
    output reg valid_out,
    input wire ready_out
);
    reg [7:0] mem [0:3];
    reg [1:0] wr_ptr, rd_ptr;
    reg [2:0] count;
    
    // Buffered count signals for different consumers
    reg [2:0] count_for_empty;
    reg [2:0] count_for_full;
    reg [2:0] count_for_inc;
    reg [2:0] count_for_dec;
    
    // Buffer registers for high fanout count signal
    always @(posedge clk) begin
        if (rst) begin
            count_for_empty <= 0;
            count_for_full <= 0;
            count_for_inc <= 0;
            count_for_dec <= 0;
        end else begin
            count_for_empty <= count;
            count_for_full <= count;
            count_for_inc <= count;
            count_for_dec <= count;
        end
    end
    
    // Status signals with buffered count
    wire empty, full;
    assign empty = (count_for_empty == 0);
    assign full = (count_for_full == 4);
    
    // Ready signal using buffered count
    always @(*) begin
        ready_in = !full;
    end
    
    // Valid signal using buffered count
    always @(*) begin
        valid_out = !empty;
    end
    
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            data_out <= 8'h0;
        end else begin
            // Default case - maintain current count
            count <= count;
            
            // Write logic with buffered count for increment
            if (valid_in && ready_in) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                
                // Read happening simultaneously
                if (valid_out && ready_out) begin
                    // Write and read simultaneously - count stays the same
                    count <= count;
                end else begin
                    // Only write - increment count
                    count <= count_for_inc + 1;
                end
            end
            // Read logic with buffered count for decrement
            else if (valid_out && ready_out) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                // Only read - decrement count
                count <= count_for_dec - 1;
            end
        end
    end
endmodule