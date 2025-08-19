module circular_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    input wire read_en,
    output reg [7:0] data_out,
    output reg empty,
    output reg full
);
    reg [7:0] mem [0:3];
    reg [1:0] wr_ptr, rd_ptr;
    reg [2:0] count;
    
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0; rd_ptr <= 0; count <= 0;
            empty <= 1; full <= 0;
        end else begin
            if (write_en && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (read_en && !empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
            empty <= (count == 0);
            full <= (count == 4);
        end
    end
endmodule