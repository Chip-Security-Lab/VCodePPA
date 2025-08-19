module delayed_write_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire trigger,
    output reg [15:0] data_out
);
    reg [15:0] buffer;
    reg write_pending;
    
    always @(posedge clk) begin
        if (trigger) begin
            buffer <= data_in;
            write_pending <= 1'b1;
        end else if (write_pending) begin
            data_out <= buffer;
            write_pending <= 1'b0;
        end
    end
endmodule