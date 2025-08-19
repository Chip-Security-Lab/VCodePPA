module w2n_bridge #(parameter WIDE=32, NARROW=8) (
    input clk, rst_n,
    input [WIDE-1:0] wide_data,
    input wide_valid,
    output reg wide_ready,
    output reg [NARROW-1:0] narrow_data,
    output reg narrow_valid,
    input narrow_ready
);
    localparam RATIO = WIDE/NARROW;
    reg [WIDE-1:0] buffer;
    reg [$clog2(RATIO):0] count;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            buffer <= 0; count <= 0; narrow_valid <= 0; wide_ready <= 1;
        end else if (wide_valid && wide_ready && count == 0) begin
            buffer <= wide_data;
            narrow_data <= wide_data[NARROW-1:0];
            narrow_valid <= 1;
            wide_ready <= 0;
            count <= 1;
        end else if (narrow_valid && narrow_ready) begin
            if (count < RATIO) begin
                narrow_data <= buffer[count*NARROW +: NARROW];
                count <= count + 1;
            end
            if (count == RATIO-1) begin
                count <= 0;
                wide_ready <= 1;
                narrow_valid <= 0;
            end
        end
    end
endmodule