//SystemVerilog
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
    
    // Buffer registers for high fan-out count signal
    reg [$clog2(RATIO):0] count_buf1;
    reg [$clog2(RATIO):0] count_buf2;
    reg [$clog2(RATIO):0] count_buf3;
    
    // First stage of pipeline to distribute count
    always @(posedge clk) begin
        if (!rst_n) begin
            count_buf1 <= 0;
            count_buf2 <= 0;
            count_buf3 <= 0;
        end else begin
            count_buf1 <= count;
            count_buf2 <= count;
            count_buf3 <= count;
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            buffer <= 0; 
            count <= 0; 
            narrow_valid <= 0; 
            wide_ready <= 1;
        end else if (wide_valid && wide_ready && count_buf1 == 0) begin
            buffer <= wide_data;
            narrow_data <= wide_data[NARROW-1:0];
            narrow_valid <= 1;
            wide_ready <= 0;
            count <= 1;
        end else if (narrow_valid && narrow_ready) begin
            if (count_buf2 < RATIO) begin
                narrow_data <= buffer[count_buf2*NARROW +: NARROW];
                count <= count + 1;
            end
            if (count_buf3 == RATIO-1) begin
                count <= 0;
                wide_ready <= 1;
                narrow_valid <= 0;
            end
        end
    end
endmodule